class SearchController < ApplicationController
  def search
    reset_page
    # saves in session for pages
    session[:query] = params[:query]
    if session[:query]
      @query = session[:query]
      @users = User.where name: [@query.capitalize, @query.downcase]
      @groups = Group.where name: [@query.capitalize, @query.downcase]
      @modules = CodeModule.where name: [@query.capitalize, @query.downcase]
      @tags = Hashtag.tagged(session[:query])

      # show a listing of groups for empty searches
      if session[:query] == ""
        @groups = Group.all.sort_by(&:rank).reverse
      elsif @users.empty? and @groups.empty? and @modules.empty? and @tags.empty?
        @no_results = "No results were found for #{@query}."
      end

      @all_results = [] # collects results into one array
      @users.each { |user| @all_results << user }
      @groups.each { |group| @all_results << group }
      @modules.each { |_module| @all_results << _module }
      @tags.each { |tag| @all_results << tag }
      
      @results = @all_results.
        # drops first several posts if :feed_page
        drop((session[:page] ? session[:page] : 0) * page_size).
        # only shows first several posts of resulting array
        first(page_size)
    end
    # logs the visit with the contextual data
    Activity.log_action(current_user, request.remote_ip.to_s, "search", nil, @query)
  end
  
  private
  
  def scan_all
    
  end
end
