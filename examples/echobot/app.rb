require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'
require 'faraday'
require 'byebug'

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = '29a1930dc9b7dcf647626fd878fb48fc'
    config.channel_token = 'OSZEquTZ8SEboALkvQiqCGFz85Vk2AajX4m+kf1L/R2eiDgfyyEgp51qkGtcpTXJhjSuCLUm4QAvYJpL7mjCe3247WYf86rdoyC00clouSf7bL4WtiLujJtw1rOngbF61Ah0RRO3PZ/QnyG6rwYSewdB04t89/1O/w1cDnyilFU='
  }
end

def get_image_url_form_imgur(word)
  conn = Faraday.new(:url => 'https://api.imgur.com')
  response = conn.get '/3/album/skSRl6l/images' do |req|
    req.headers['Authorization'] = 'Client-ID 88377d50670b893'
  end

  data = JSON.parse(response.body)['data'].select { |d| d['description'] == word }
  if data.any?
    data.sample['link']
  else
    nil
  end
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)

  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        if image_url = get_image_url_form_imgur(event.message['text'])
          message = {
            type: 'image',
            originalContentUrl: image_url,
            previewImageUrl: image_url
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
  }

  "OK"
end
