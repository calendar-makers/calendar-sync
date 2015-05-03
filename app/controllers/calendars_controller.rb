class CalendarsController < ApplicationController
  before_filter do
    if request.ssl? && Rails.env.production?
      redirect_to :protocol => 'http://', :status => :moved_permanently
    end
  end

  def preprocess_header_footer
    css_base
    css_image
    css_script
    css_li
    css_a_form_link
    css_section
    @head1 = (@page.at_css "head").inner_html
    @header = @page.at_css "header"
    @footer = @page.at_css "footer"
    #@text = @head1.inner_html
    #@head1 = @text
  end

  def css_base
    @page.css("base").each do |tag|
      tag.remove()
    end
  end

  def css_image
    @page.css("img").each do |tag|
      if tag["src"]!=nil and tag["src"][0]=='/'
        tag.set_attribute('src', 'http://www.natureinthecity.org' + tag["src"])
      end
    end
  end

  def css_script
    @page.css("script").each do |tag|
      if tag["src"]!=nil and tag["src"].match('/media')
        tag.set_attribute('src', 'http://www.natureinthecity.org' + tag["src"])
      end
    end
  end

  def css_li
     @page.css("li").each do |tag|
      if tag["class"] != nil and tag["class"] =="item-144"
        tag["class"] = "item-144 current"
      end
    end
  end

  def css_a_form_link
    @page.css("a,form,link").each do |tag|
      if tag["href"] !=nil and tag["href"][0] =='/'
        tag.set_attribute('href', "http://www.natureinthecity.org" + tag["href"])
      end
    end
  end

  def css_section
    @section =""
    @page.css("section").each do |elem|
      if elem["id"] == "gk-bottom"
        @section = elem
      end
    end
  end


  def preprocess_for_bad_request
    file = File.join(Rails.root, 'features', 'support', 'backup.html')
    @page = Nokogiri::HTML(File.read(file))
  end

  def show
    begin
      @page = Nokogiri::HTML(open("http://www.natureinthecity.org/"))
      #preprocess_for_bad_request
    rescue Exception
      preprocess_for_bad_request
    end
    preprocess_header_footer

    if flash[:notice].nil? # Prevent Meetup synchronization if have incoming message
      events = Event.synchronize_upcoming_events
      display_synchronization_result(events)
    end
  end

  def display_synchronization_result(events)
    if events.nil?
      flash.now.notice = "Could not pull events from Meetup"
    elsif events.empty?
      flash.now.notice = "The Calendar and Meetup are synched"
    else
      flash.now.notice = 'Successfully pulled events: ' + CalendarsController.get_event_info(events) + ' from Meetup'
    end
  end

  def self.get_event_info(events)
    info = []
    if events.size < 30
      events.each {|event| info << event[:name]}
    else
      events[0..30].each {|event| info << event[:name]}
      info << 'and more'
    end
    info.join(', ')
  end

  def respond_js
    respond_to do |format|
      format.js
    end
  end

=begin
  def show_event
    @event = Event.find params[:id]
    formatTime(@event)
    new_guests = @event.merge_meetup_rsvps
    @non_anon_guests_by_first_name = @event.guests.order(:first_name).where(is_anon: false)
    respond_js
  end

  def formatTime(event)
    startTime = event.start.strftime('%b %e, %Y at %l:%M %P')
    endTime = ""
    if event.end
      if (event.end - event.start) >= 1
        endTime = event.end.strftime('%b %e, %Y at %l:%M %P')
      else
        endTime = event.end.strftime('%l:%M %P')
      end
    end
    @timePeriod = startTime
    @timePeriod = startTime + ' to ' + endTime unless endTime == ""
  end


  def show_edit
    @event = Event.find params[:event_id]
    respond_js
  end

  def show_new
    @event = Event.new
    respond_js
  end
=end

  def create_guest
    @event = Event.find(params[:event_id])
    if !Guest.fields_valid?(guest_params)
      render :nothing => true
      return
    end
    handle_guest_registration
    GuestMailer.rsvp_email(@guest, @event).deliver
    respond_js
  end

  def handle_guest_registration
    @guest = Guest.find_by_email(guest_params[:email]) || Guest.create!(guest_params)
    @guest.registrations.build({:event_id => params[:event_id], :guest_id => @guest.id})
    @guest.save
  end

  private

  def guest_params
    params.require(:guest).permit(:first_name, :last_name, :phone, :email, :address, :is_anon)
  end
end
