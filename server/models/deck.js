const mongoose = require('mongoose')

const deckSchema = new mongoose.Schema({
    username:String,
    deck_name:String,
    cards:[String]
})

module.exports = mongoose.model('deck',deckSchema)
