Messages = require './src/messages'

#messageBodyList = require('./data/message').rsvpReminderMessage
messageBodyList = require('./data/message').exampleMessageSplit
#numbers = require('./data/numbers').rsvpdYes
numbers = require('./data/numbers').listOne

TEST_NUMBERS = ['my-number', 'another-number']
TEST_MESSAGE = "hey! this is a message sent via script! #{Messages.EMOJI.SUNGLASSES}"
# For testing how and where SMSs are split
TEST_LONG_MESSAGE = '1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890x'

# Note that the `body` option can be a string or an array of strings -- if it's
# an array, the script will send each string in the array to a given phone
# number one by one with a small delay in between each to ensure they arrive in
# the right order, otherwise the recipient can receive them all mixed up
messages = new Messages {body: messageBodyList}
messages.sendMessages TEST_NUMBERS, (err) ->
  console.log 'Done!'
