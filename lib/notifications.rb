require 'fileutils'
require 'redcarpet'
require 'mailgun'


# ======================================
# Notifications CLASS
# ======================================
class Notification

  def initialize(mail_gunkey)
    mg_client = Mailgun::Client.new mailgun_key
  end

  def send(sender, recipients, subject, markdown_message)
    message=Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(markdown)

    message_params = {:from    => sender,  
                      :to      => recipients,
                      :subject => subject,
                      :html    => message}
                    # :text    => 'It is really easy to send a message!'}

    mg_client.send_message "posta.5p2p.it", message_params
  end
end