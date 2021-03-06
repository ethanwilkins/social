class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  helper_method :current_user, :page_size, :reset_page, :paginate, :decrypt_message, :color_theme, :beautify

  private
  
  def beautify(html)
		output = ""
    HtmlBeautifier::Beautifier.new(output).scan(html)
    return output
  end
  
  def color_theme(default)
    if current_user and current_user.color_theme
      case current_user.color_theme
        when "light"
          return default
        when "dark"
          return "#{default}_dark"
      end
    else
      return default
    end
  end

  def current_user
    @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
  end
  
  def decrypt_message(message)
		key = ActiveSupport::KeyGenerator.new(message.created_at.to_s).generate_key(message.salt)
		encryptor = ActiveSupport::MessageEncryptor.new(key)
    message = encryptor.decrypt_and_verify(message.text)
    return message
  end
  
  def paginate(items)
    return items.reverse.
      # drops first several posts if :feed_page
      drop((session[:page] ? session[:page] : 0) * page_size).
      # only shows first several posts of resulting array
      first(page_size)
  end
  
  def reset_page
    # goes back to top at refresh
    unless session[:more]
      session[:page] = nil
    end
    session[:more] = nil
  end
  
  # increments/decrements page flags
  # sets to 1 if nil and change is 1
  def page(page_flag, change=0)
    if session[page_flag]
      session[page_flag] += change
    elsif change == 1
      session[page_flag] = 1
    end
  end
  
  def page_size
    @page_size = 5
  end
end
