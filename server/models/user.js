const mongoose = require('mongoose')

const userSchema = new mongoose.Schema({
    username:{type:String, index:{unique:true}},
    password:String,
    friends:[String]
})

module.exports = mongoose.model('user',userSchema)
