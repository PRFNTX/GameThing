const express = require("express")
const app = express()
const mongoose = require('mongoose')

const jwt=require('jsonwebtoken')
const bcrypt = require('bcrypt')

const User = require('./models/user')
const Deck = require('./models/deck')

const http = require('http')
const ws = require('ws').Server

const PORT=process.env.PORT || 443

const server = http.Server(app)

const wss = new ws({
    server: server,
    perMessafeDefalte:false
})



server.listen(PORT,()=>{
    console.log('socket running')
})

app.listen(80,()=>{
    console.log('endpoints')
})


mongoose.connect('mongodb://localhost:27017/NotFaeria')


app.use(express.json())
app.use(express.urlencoded({extended:true}))


let chat_channels = []

let games = [{'name':'fake game, please ignore',owner:{name:'nop'},challenger:null,started:false}]

//chanels
function join_channel(name, member){
    //join events to keep member lists updated
    //send joiner the member list
    let found_channel
    chat_channels.forEach(channel=>{
        if (channel.name===name){
            found_channel = channel
        }
    })
    if (!found_channel){
        chat_channels.push({
            name,
            members:[member]
        })
    } else {
        found_channel.members.push(member)
    }
}

function leave_channel(name, member,disc=false){
    //leave events to keep lists update
    chat_channels.forEach((chat,i)=>{
        if (chat.name===name){
            chat_channels[i] = chat.members.filter(usr=>usr.name!==member.name)
            chat_channels[i].members.forEach(member=>member.send(JSON.stringify({"chat_leave":member.name})))
        }
    })
    if (!disc){
        member.sent(JSON.stringify({'leave':""}))
    }
    
}

function message_channel(channel_name,sent_by,message){
    let found
    chat_channels.forEach(chat=>{
        if (chat.name===channel_name){
            found=chat
        }
    })
    if (found){
        found.members.forEach(member=>{
            member.send(JSON.stringify({'msg_channel':{name:sent_by.name,message:message}}))
        })
    }
}

//games

function game_list(res){
    let response = {'game_list':games
    .filter(game=>!game.started && !game.challenger && game.owner)
    .map(game=>{
        console.log(game)
        return {'name':game.name, owner:game.owner.name}
    })}

    res.send(JSON.stringify(response))
}

function create_game(name,owner){
    console.log('CREATE OWNER',owner.name)
    if (games.filter(game=>game.name===name).length===0){
        games.push({
            name:name,
            owner:owner,
            challenger:null,
            started:false
        })
        
        
        owner.send(JSON.stringify({'create':name}))
        return true
    } else {
        owner.send(JSON.stringify({'collision':name}))
        return false
    }
}

function join_game(name,member){
    let found
    games.forEach(game=>{
        if ((game.name===name) && (!game.challenger)){
            found = game
        }
    })
    if (found){
        found.challenger = member
        found.owner.send(JSON.stringify({'join':member.name}))
        found.challenger.send(JSON.stringify({'join':found.owner.name}))
    }
}

function leave_game(name,member,disc=false){
    let found
    games.forEach(game=>{
        if (game.name===name){
            found = game
        }
    })
    if (found){
        found.challenger = null
        found.owner.send(JSON.stringify({'drop':""}))
        if (!disc){
            member.send(JSON.stringify({'drop':""}))
    }
}
    
}

function close_game(name,owner_disc=false,member_disc=false){
    //message members that game has closed
    let found
    games.forEach(game=>{
        if (game.name===name){
            game.started=true
            if (!owner_disc){
                game.owner.send(JSON.stringify({'close':""}))
            }
            if (!member_disc && game.challenger){
                game.challenger.send(JSON.stringify({'close':""}))
            }
            
        }
    })
    games = games.filter(game=>game.name!==name)
}

function start_game(name){
    let found
    games.forEach(game=>{
        if (game.name===name){
            game.started=true
            game.owner.send(JSON.stringify({'start':"0"}))
            game.challenger.send(JSON.stringify({'start':"1"}))
        }
    })
}

function ready_game(name, value, by){
    let found 
    games.forEach(game=>{
        if (game.name===name){
            found = game
            
        }
    })
    if (found && found.challenger){
        try {
           if (found.challenger.name===by){
               found.owner.send(JSON.stringify({ready:value}))
            } else if (found.owner.name===by){
                found.challenger.send(JSON.stringify({ready:value}))
            }
        } catch(err){
            console.log(err)
        }
    }
}

function deck_game(name, value, by){
    let found 
    games.forEach(game=>{
        if (game.name===name){
            found = game
        }
    })
    if (found && found.challenger){
        try {
            if (found.challenger.name===by){
                found.owner.send(JSON.stringify({deck:value}))
            } else if (found.owner.name===by){
                found.challenger.send(JSON.stringify({deck:value}))
            }
        } catch(err){
            console.log(err)
        }
    }
}

//ACTIONS

function action(name,params){
    let found
    games.forEach(game=>{
        if (game.name===name){
            found = game
        }
    })
    //params [ 0 ] = player num
    if (found){

        
        let send_to
        if (params.player==0){
            send_to = found.challenger
            
        } else {
            send_to = found.owner
            
        }

        //params[ 1 ] action name (to .call())
        //params[ 2 ] action target
        //params[ 3 ] setState({this thing})
        send_to.send(JSON.stringify({game_action:{player:params.player, type:params.type, target:params.target, state:params.state}}))
}
}
//SOCKET

//connect user
    //user identifies {'greeting':username}
    //user commands:
        //create game room {'create':name}
        //join game room {'join':name}
        //drop
        //game room starts game {'start':name}
            //game actions {'action': {state stuff}}
        
        //send message {'msg_user':'message'}
        //join chat channel {'channel': name}
            //message channel {'msg_channel':[channel,message]}

        

wss.on('connection', (socket, req)=>{
    console.log('connected')
    let own_game
    let in_game
    socket.on('message', event=>{
        console.log(event)
        let command = JSON.parse(event)
        if (Object.keys(command)[0]==='greeting'){
            socket.name=command['greeting']
            socket.send(JSON.stringify({'hello':socket.name}))
        }
        let key = Object.keys(command)[0]
        let value = command[key]
        if (socket.hasOwnProperty('name')){
            switch (key){
                case 'create':
                    console.log('create')
                    if (create_game(value,socket)){
                        own_game=value
                    }
                    break;
                case 'game_list':
                    game_list(socket)
                    break;
                case 'join':
                    join_game(value,socket);
                    in_game=value
                    break;
                case 'drop':
                    leave_game(value,socket);
                    in_game = null
                    break;
                case 'close':
                    close_game(own_game, value);
                    own_game=null
                    break;
                case 'start':
                    start_game(in_game||own_game);
                    break;
                case 'join_channel':
                    join_channel(value,socket);
                    break;
                case 'leave_channel':
                    leave_channel(value,socket);
                    break;
                case 'msg_channel':
                    message_channel(value[0],socket,value[1]);
                    break;
                case 'game_action':
                    action(in_game||own_game,value);
                    break;
                case 'ready':
                    ready_game(in_game||own_game, value, socket.name)
                    break;
                case 'deck_name':
                    deck_game(in_game||own_game, value, socket.name)
                    break;
                default:
                    socket.send(JSON.stringify({'invalid':value}));
                    break;
                    

        }
        

        }
        
    })
    socket.on('error', error=>console.log(error))

    socket.on('close', error=>{
        if (own_game){
            close_game(own_game,true)
            own_game=null
        } else if (in_game){
            leave_game(in_game,false,true)
            in_game=null
        }
        
    })
    
})

_on_time = ()=>{
    msg = "A"
    
    wss.clients.forEach(client=>{
        try{
            client.send(msg)
            
        } catch(err){
            console.log(err)
        }
    })
}

setInterval(_on_time,15000)





function check(req,res,next){
    console.log("body", req.body)
    next()
}

app.get('/decks', authenticate, check,(req,res)=>{
    const user = req.user.username
    Deck.find({username:user}).then(
        decks=>{
            console.log(decks)
            
            const deckNames = decks.map(deck=>{return {deck_name:deck.deck_name,cards:deck.cards}})
            res.status(200).json(deckNames)
        }
    ).catch(
        err=>{
            console.log(err)
            res.status(403).json({message:'could not load decks'})
        }
    )
})

app.get('/decks/:name', authenticate, (req,res)=>{
    
    const user = req.user.username
    Deck.findOne({username:user,deck_name:req.params.name}).then(
        deck=>{
            
            res.status(200).json(deck)
        }
    ).catch(
        err=>{
            console.log(err)
            res.status(403).json({message:'could not load decks'})
        }
    )
    
})

app.put('/decks/:name', authenticate, (req,res)=>{
    const changes = req.body
    const user = req.user.username
    console.log('changes',changes)
    console.log('params', req.params.name)
    Deck.findOne({username:user,deck_name:req.params.name}).then(
        found=>{
            if (found){
                Object.keys(changes).forEach(prop=>{
                    console.log(prop)
                    
                    found[prop]=changes[prop]
                })
                return found.save()
            } else {
                console.log("CREATE")
                return Deck.create({
                    username:user,
                    deck_name:changes.deck_name,
                    cards:changes.cards
                })
            }
        }
    ).then(
        result =>{
            res.status(200).json({message:'deck updated successfully'})
        }
    ).catch(err=>{
        console.log(err)
        res.status(501).json({message:'something failed, saving deck'})
    })
})

app.post('/decks/:name', authenticate,(req,res)=>{
    const deckList = req.body.cards
    const user = req.user.username
    console.log('create deck for ', user)
    Deck.findOne({username:user,deck_name:req.params.name}).then(
        found=>{
            if (found){
                found.cards = deckList
                return found.save()
            } else {
                return Deck.create({
                    username:user,
                    deck_name:req.params.name,
                    cards:deckList
                })
            }
        }
    )
    .then(
        ret=>{
            console.log('deck made')
            res.status(200).json({message:'deck create'})
        }
    ).catch(
        err=>{
            console.log(err)
            res.status(403).json({message:'could not save deck'})
        }
    )
})

app.post('/register', (req,res)=>{
    const username = req.body.username
    const password = req.body.password
    register(username,password).then(
        user=>{
            //add jwt
            res.set({authenticate:signJWT({username:user.username,id:user._id})})
            delete user.password
            res.status(200).json(user)
        }
    ).catch(
        err=>{
            console.log(err)
            res.status(401).json({message:'failed to create user'})
        }
    )
})

app.post('/login',(req,res)=>{
    const username = req.body.username
    const password = req.body.password
    verify(username,password).then(
        user=>{
            //add jwt
            res.set({authenticate:signJWT({username:user.username,id:user._id})})
            delete user.password
            res.status(200).json(user)
        }
    ).catch(
        err=>{
            console.log(err)
            res.status(403).json({message:'failed to log in'})
        }
    )
})

app.get('/user/friends', authenticate, (req, res)=>{
    const user = req.user.id
    User.findOne({_id:user}).then(
        user=>{
            res.status(200).json(user.friends)
        }
    ).catch(
        err=>{
            res.status(404).json({message:'could not get friends'})
        }
    )
})

app.post('/user/friends', authenticate, (req,res)=>{
    const user = req.user.id
    const friend = req.body.friend
    User.findOne({username:friend}).then(
        foundUser=>{
            return User.findOne({_id:user}).then(
                user=>{
                    user.friends.push(foundUser.username)
                    return user.save()
                }
            )
        }
    )
    .then(
        savedUser=>{
            res.status(200).json({message:'friend added'})
        }
    )
    .catch(err=>{
        res.status(500).json({message:'friend add failed'})
    })
})

app.get('/games', authenticate, (req,res)=>{
    res.status(200).json(games.filter(game=>!game.started))
})

app.get('/channels', authenticate, (req,res)=>{
    res.status(200).json(chat_channels)
})


function register(username, password){

    return new Promise((resolve,reject)=>{
        bcrypt.genSalt(12,(err,salt)=>{
            if (err){
                return reject(err)
            }
            bcrypt.hash(password,salt,(err,hash)=>{
                if (err){
                    return reject(err)
                }
                console.log(hash)
                
                User.create({
                    username:username,
                    password:hash,
                }, (err,user)=>{
                    if (err){
                        console.log('hash err')
                        return reject(err)
                    }
                    if (!user){
                        console.log("null user")
                        return reject("failed to make user")
                    }
                    return resolve(user)
                })
            })
        })
    })
}

function verify(username, password){
    return new Promise((resolve,reject)=>{
        User.findOne({'username':username},(err,founduser)=>{
            if (err){
                return reject(err)
            }
            if (!founduser){
                return reject("user not found")
            }
            bcrypt.compare(password,founduser.password,(err,res)=>{
                console.log('res',res)
                if (err){
                    console.log('err',err)
                    return reject(err)
                }
                if (res){
                    return resolve(founduser)
                } else {
                    return reject("password mismatch")
                }
            
            })
        })
    })
}

function authenticate(req,res,next){
    let token = req.headers.authenticate

    verifyJWT(token).then(
        user =>{
            req.user = user.data
            console.log('auth good')
            next()
        }
    ).catch(
        err=>{
            console.log('auth bad')
            res.status(403).json({message:'authentication failed'})
        }
    )
}

function signJWT(obj){
    	let token = jwt.sign(
			{data:obj},
			'secret',
			 {algorithm:'HS256'}
		)
	return token
}


function verifyJWT(token){
	//copied code
	return new Promise ((resolve,reject)=>{
		jwt.verify(token,'secret', (err,tokenDecoded)=>{
			if (err || !tokenDecoded){
				return reject(err);
			}
			resolve(tokenDecoded)
		})
	})
}

/*
app.listen(PORT, ()=>{
    console.log('connected on '+ PORT)
})
*/




