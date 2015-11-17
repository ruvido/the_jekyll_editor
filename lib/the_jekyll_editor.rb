#!/usr/bin/env ruby

require 'fileutils'
require 'redcarpet'
require 'mailgun'



# ======================================
# Notifications CLASS
# ======================================
class Notification

  def initialize()
    @markdown_message = ''
  end

  def add(markdown_message)
    @markdown_message = @markdown_message + markdown_message
  end

  def send(mailgun_key, sender, recipients, subject)
    client = Mailgun::Client.new mailgun_key
    message=Redcarpet::Markdown.new(Redcarpet::Render::HTML.new).render(@markdown_message)

    message_params = {:from    => sender,  
                      :to      => recipients,
                      :subject => subject,
                      :html    => message}
                    # :text    => 'It is really easy to send a message!'}

    client.send_message "posta.5p2p.it", message_params
  end
end

# ======================================
# Draft CLASS
# ======================================
class Draft
  attr_accessor :filename, :basename, :title, :author, :date, :slug, :header, :image,
                :jkname, :preview, :preview_field, :publish, :publish_field,
                :config
  def initialize(filename,blog)
    @filename = filename
    @basename = File.basename(filename)
    @header   = false
    @image    = false
    @title    = ''
    @author   = ''
    @date     = ''
    @slug     = ''
    @preview  = false
    @publish  = false
    @preview_field  = ''
    @publish_field  = ''
    @jkname   = 'Untitled.md'
    @status_v = 'draft'
    @config   = blog

    # ---- Ingest entire file  ----------
    text = File.read(filename)

    # ---- Read header ------------------
    new_line_split=/\r?\n/
    # if text.split("\r\n")[0] == "---"
    if text.split(new_line_split)[0] == "---"
      @header = true
      splitext = text.split("---")
      head = splitext[1]
      head.split("\n").each do |line|
        k,v=line.split(":")
        # puts k,v
    # ---------------------------------
        # if k =~ /preview/ and v =~ /ok/
        if k == 'preview' and v =~ /ok/
          @preview_field=true
        end
    # ---------------------------------
        if k == 'publish' and v =~ /ok/
          @publish_field=true
        end
    # ---------------------------------
        if k =~ /date/
          date=v
          d,m,y = v.split('-')
          day   = '%02d' % d
          month = '%02d' % m
          year  = '%04d' % y
          @date=year + "-" + month + "-" + day
        end
    # ---------------------------------
        if k =~ /slug/
          @slug=v.strip
        end
      # ---------------------------------
        if k =~ /title/
          @title=v.strip
        end
      # ---------------------------------
        if k =~ /author/
          @author=v.strip
        end
        if k == "image"
          @image=v.strip
        end
      end
    end
  end
  # --------------------------------
  def status
    if @publish_field==true and @date!="" and @slug!="" and @title!=""
      status_v = 'publish' 
      if image and !File.file?("#{File.dirname(filename)}/#{image}")
        status_v = 'preview' 
      end
      @jkname = date + "-" + slug + ".md"
    elsif preview_field == true
      status_v = 'preview'
    else
      status_v = 'draft'
    end
    return status_v
  end
  def missing
    if @date == ''
      puts "ERR: date is missing"
    end
    if @slug == ''
      puts "ERR: slug is missing"   
    end
    if @title == ''
      puts "ERR: title is missing"      
    end
    if @image and !File.file?("#{File.dirname(filename)}/#{image}")
      puts "ERR: image is missing"      
    end
    if @publish_field == ''
      puts "WAR: publish field is missing"
    end

    # else
    #   puts "OK: article ready"
    # end  
  end
  # --------------------------------
  def to_previews

    new_filename = "#{config.blog_previews}/#{basename}"
    FileUtils.cp( filename, new_filename )

    new_filename = "#{config.dump_previews}/#{basename}"
    FileUtils.mv( filename, new_filename ) unless filename == new_filename
    # FileUtils.mv( filename, "#{config.dump_trash}/#{basename}__#{time.usec}")

    if image

      old_image = "#{File.dirname(filename)}/#{image}"
      new_image = "#{config.dump_previews}/#{image}"
      # new_image = "#{config.blog_images}/#{image}"


      if File.file?(old_image) and old_image != new_image
        FileUtils.mv( old_image, new_image ) 
      end

      # copy the image in a public (accessible) place
      public_image = "#{config.blog_previews}/#{image}"
      FileUtils.cp( new_image, public_image ) 



    end 


    return new_filename
  end
  # --------------------------------
  def to_posts
    # post_dir = $blog_dir + "/_posts/"
    # prev_dir = $blog_dir + "/previews/"

    # new_filename = "#{config.blog_posts}/#{jkname}"
    # new_filename = config.blog_posts + jkname
    FileUtils.cp( filename, "#{config.blog_posts}/#{jkname}" )
    
    # old_preview = config.blog_previews + File.basename(filename)
    old_preview = "#{config.blog_previews}/#{basename}"
    if File.file?(old_preview)
      FileUtils.rm( old_preview )
    end

    new_filename = "#{config.dump_posts}/#{jkname}"
    FileUtils.mv( filename, new_filename ) unless filename == new_filename

    if image

      old_image = "#{File.dirname(filename)}/#{image}"
      new_image = "#{config.blog_images}/#{image}"
      FileUtils.cp( old_image, new_image )

      public_image = "#{config.blog_previews}/#{image}"
      FileUtils.rm( public_image )

    end 

    return new_filename
  end 
end



# ======================================
# Blog CLASS
# ======================================
class Blogdata
  attr_accessor :dump, :dump_drafts, :dump_previews, :dump_posts, :dump_images,
                :blog, :blog_previews, :blog_posts, :blog_images

  def initialize( idump , iblog)
    # @filename         = configfile
    @dump             = idump
    @dump_drafts      = ''
    @dump_previews    = ''
    @dump_posts       = ''
    @blog             = iblog
    @blog_previews    = ''
    @blog_posts       = ''
    @blog_images      = ''

    # config = File.read(@filename)
    # config.split("\n").each do |line|
      # k,v=line.split(":")
      # puts k, v
      # if k =~ /dump/
        # .strip removes any extra space from the dir path
        # @dump         = "#{v.strip}"
    @dump_drafts  = "#{@dump}/drafts"
    @dump_previews= "#{@dump}/previews"
    @dump_posts   = "#{@dump}/published"
    @dump_images  = "#{@dump_posts}/images" 

    FileUtils::mkdir_p @dump unless Dir.exist?(@dump)
    FileUtils::mkdir_p @dump_drafts unless Dir.exist?(@dump_drafts) 
    FileUtils::mkdir_p @dump_previews unless Dir.exist?(@dump_previews) 
    FileUtils::mkdir_p @dump_posts unless Dir.exist?(@dump_posts)
    FileUtils::mkdir_p @dump_images unless Dir.exist?(@dump_images) 


      # end
      # if k =~ /blog/
        # .strip removes any extra space from the dir path
        # @blog         = "#{v.strip}"
    @blog_previews= "#{@blog}/previews"
    @blog_posts   = "#{@blog}/_posts"
    @blog_images  = "#{@blog}/images/posts"

    FileUtils::mkdir_p @blog unless Dir.exist?(@blog)
    FileUtils::mkdir_p @blog_previews unless Dir.exist?(@blog_previews)
    FileUtils::mkdir_p @blog_posts unless Dir.exist?(@blog_posts)
    FileUtils::mkdir_p @blog_images unless Dir.exist?(@blog_images)

  end

  def push
 
    Dir.chdir @blog
    # puts `git status`
    # msg1 = "Changes not staged for commit:"
    `git add --all .`
    if `git commit -a -m 'commit'` =~ /nothing to commit, working directory clean/
      puts 'nothing to commit'
    else
      `git push`
      puts 'push blog forward!'
    end
  end
end