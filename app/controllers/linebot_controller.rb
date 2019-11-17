class LinebotController < ApplicationController
  require 'line/bot'
  require 'json'
  require 'open-uri'

  skip_before_action :verify_authenticity_token

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: call_weather
          }
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    head :ok

    p call_weather
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config| 
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end

  def call_weather
    API_KEY = ENV['OPEN_WEATHER_API_KEY']
    BASE_URL = 'http://api.openweathermap.org/data/2.5/forecast'

    response = open(BASE_URL + "?q=Osaka,jp&APPID=#{API_KEY}")
    JSON.pretty_generate(JSON.parse(response.read))
  end
end
