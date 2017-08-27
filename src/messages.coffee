async = require 'async'
twilio = require 'twilio'
config = require '../config/twilio_credentials'
Logger = require './logger'

# http://unicode.org/emoji/charts/full-emoji-list.html
EMOJI =
  GRINNING: String.fromCodePoint 0x1f604
  SUNGLASSES: String.fromCodePoint 0x1f60e

FROM_NUMBER = config.phoneNumbers.from

# Class for sending SMS messages via Twilio to a list of phone numbers and
#   logging the results to a file
# @param options [Object] options object for the messages instance
# @option options.body [String|Array<String>] body of message or messages to
#   send (if an array of strings, messages are send to recipients in parallel
#   but the messages are sent in order -- if the first fails, the remainder are
#   not attempted); required
# @option options.from [String] phone number to send messages from; defaults to
#   normal Twilio sending number
module.exports = class Messages
  @EMOJI: EMOJI

  constructor: (options = {}) ->
    @fromPhoneNumber = options.from || FROM_NUMBER
    @messageBody = options.body
    throw new Error 'Missing message body' unless @messageBody
    unless Array.isArray @messageBody
      @messageBody = [@messageBody]

    # NOTE: switch this to the config.test credentials to use your test account
    # instead of your live one
    @twilioClient = twilio config.live.accountSid, config.live.authToken

  # @param phoneNumbers [Array<String>] list of phone numbers to send the
  #   message(s) to
  sendMessages: (phoneNumbers, cb) ->
    @logger = new Logger
    console.log "Sending to #{phoneNumbers.length} numbers:"
    console.log "  #{number}" for number in phoneNumbers
    @_sendMessageList phoneNumbers, cb

  _sendMessageList: (phoneNumbers, cb) ->
    @logger.logMessageHeader {from: @fromPhoneNumber, messages: @messageBody}

    async.forEachSeries phoneNumbers
    , (toPhoneNumber, numberCb) =>
      formattedToPhoneNumber = @_formatPhoneNumber toPhoneNumber
      finalTwilioResponse = null

      async.forEachSeries @messageBody
      , (messageBody, messageCb) =>
        message =
          body: messageBody
          from: @fromPhoneNumber
          to: formattedToPhoneNumber
        @_send message, (err, res) ->
          finalTwilioResponse = res
          setTimeout (-> messageCb err, res), 1000
      , (err) =>
        if err
          err.to = formattedToPhoneNumber
          @logger.logMessageFailure err
          console.error "Message delivery error! To: #{formattedToPhoneNumber}"
        else
          @logger.logMessageSuccess finalTwilioResponse
          console.log "Message successfully sent! To: #{formattedToPhoneNumber}"
        numberCb()
    , (err) =>
      console.error err if err
      @logger.end()
      cb(err)

  _send: (messageObject, cb) ->
    @twilioClient.messages.create messageObject
      .then (res) ->
        cb null, res
      .catch (err) ->
        cb err

  _formatPhoneNumber: (phoneNumber) ->
    unless phoneNumber.slice(0, 1) == '+'
      phoneNumber = '+1' + phoneNumber
    return phoneNumber
