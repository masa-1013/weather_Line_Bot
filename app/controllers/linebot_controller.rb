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
            text: judge_rain
          }
        end
      end
      client.reply_message(event['replyToken'], message)
    end
    head :ok

    puts call_weather
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config| 
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end

  def call_weather
    '作成中'
  end

  def judge_rain
    response = get_weather_from_API
    now = Time.now.strftime('%Y-%m-%d')

    response['list'].each do |data|
      next unless data['dt_txt'].split()[0] == now
      if data['weather'][0]['id'].to_i / 100 == 8
        return '今日は雨だよ'
      end
    end
    '今日は雨じゃないよ'
  end

  def get_weather_from_API
    key = ENV['OPEN_WEATHER_API_KEY']
    url = 'http://api.openweathermap.org/data/2.5/forecast'
    id = '1853909'

    response = open(url + "?id=#{id}&APPID=#{key}")
    JSON.parse(response.read)
  end
  
end
