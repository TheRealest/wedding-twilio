fs = require 'fs'
csv = require 'csv'
moment = require 'moment'

LOGS_DIRECTORY_PATH = "#{__dirname}/../logs/"
FILE_DATETIME_FORMAT = 'YYYY-MM-DD-HH-mm-ss'
LOG_DATETIME_FORMAT = 'YYYY-MM-DD HH:mm:ss'

COLUMNS = ['date', 'to', 'success', 'error']

# Simple logging handler class for writing message send results to a file
# @param options [Object] options object for the logger instance
# @option options.mode [Logger.MODES] selects the mode for the file being
#   written to; defaults to CSV mode
# @option options.path [String] filename in the logs directory to write to;
#   defaults to a file named with the current date and time
module.exports = class Logger
  @MODES:
    CSV: 'csv'
    TXT: 'txt'

  constructor: (options = {}) ->
    @logMode = options.mode || Logger.MODES.CSV

    @logFilePath = options.path || moment().format(FILE_DATETIME_FORMAT)
    @logFilePath = "#{LOGS_DIRECTORY_PATH}#{@logFilePath}.#{@logMode}"

    @logStream = fs.createWriteStream @logFilePath
    @_initCsvStream() if @logMode == Logger.MODES.CSV

  _initCsvStream: ->
    # pipe the CSV stringifier to the raw file write stream
    csvStream = csv.stringify()
    csvStream.pipe @logStream
    @logStream = csvStream

  # Write a basic log file header with data common to all messages, regardless
  #   of log mode
  # @param partialMessageObject [Object] partial message object
  # @option partialMessageObject.from [String] the phone number the message
  #   will be sent from
  # @option partialMessageObject.body [String] the message body being sent
  logMessageHeader: (partialMessageObject) ->
    @println "Sending message on: #{moment().toString()}"
    @println "From: #{partialMessageObject.from}"
    @println "Message count: #{partialMessageObject.messages.length}"
    @println "Messages:"
    @println message for message in partialMessageObject.messages
    @println()
    @logCsvColumnHeaders() if @logMode == Logger.MODES.CSV

  # If log mode is CSV, write column headers to the file
  logCsvColumnHeaders: ->
    return unless @logMode == Logger.MODES.CSV
    @logStream.write COLUMNS

  # @param messageObject [Object] the message object passed to Twilio
  # @option messageObject.to [String] the phone number the message was sent to
  # @param twilioResponse [Object] the response object from the Twilio API
  # @option twilioResponse.dateCreated [Type] optionDesc
  # @option twilioResponse. [Type] optionDesc
  logMessageSuccess: (twilioResponse) ->
    rowData =
      date: moment(twilioResponse.dateCreated).format(LOG_DATETIME_FORMAT)
      to: twilioResponse.to
      success: 'Y'
    @logStream.write @_prepareRow rowData

  logMessageFailure: (twilioError) ->
    rowData =
      date: moment().format(LOG_DATETIME_FORMAT)
      to: twilioError.to
      success: 'N'
      error: twilioError.message
    @logStream.write @_prepareRow rowData

  _prepareRow: (data) ->
    return (data[column] for column in COLUMNS)

  print: (str = '') ->
    @logStream.write str.toString()

  println: (str = '') ->
    @logStream.write [str.toString()]

  end: (str = '') ->
    @logStream.end(str.toString())
