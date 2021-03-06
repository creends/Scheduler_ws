class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:show, :edit, :update, :destroy]

  # GET /messages
  # GET /messages.json
  def index
    messages = ChatRoom.find(params[:chat_room_id]).messages.order(created_at: :desc).limit(2)
    @message = messages.first
    if messages.second
      @date = messages.second.updated_at.getlocal
      @last_date = @date.to_date
    else
      @date = Time.now
      @last_date = @date.to_date
    end
    @unread = {total: 0, chat_room: 0}
    params[:url].match(/\/chat_rooms\/#{@message.chat_room.id}/) ? @path = true : @path = false
    if @path
      ChatRoomsUser.where(user_id: current_user.id, chat_room_id: @message.chat_room.id).update(unread: 0)
    end
    current_user.chat_rooms_users.each do |chat_room_user|
      @unread[:total] += chat_room_user.unread
      if @message.chat_room == chat_room_user.chat_room
        @unread[:chat_room] = chat_room_user.unread
      end
    end
    respond_to do |format|
      format.js
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
    p 'a'
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit
  end

  # POST /messages
  # POST /messages.json
  def create
    chat_room = ChatRoom.find params[:chat_room_id]
    message = chat_room.messages.build(content: params[:message][:content])
    message.user = current_user
    chat_room.chat_rooms_users.each do |chat_room_user|
      chat_room_user.update(deleted: false)
    end
    chat_room.chat_rooms_users.each do |chat_room_user|
      if current_user != chat_room_user.user
        chat_room_user.update(unread: chat_room_user.unread + 1)
      end
    end
    message.save
    chat_room.update(active: true)
    users = []
    chat_room.users.each do |user|
      users << user.id
    end
    ActionCable.server.broadcast 'messages',
                                 users: users,
                                 chat_room_id: params[:chat_room_id],
                                 message_id: message.id
    head :ok
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      if @message.update(message_params)
        format.html { redirect_to @message, notice: 'Message was successfully updated.' }
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messages_url, notice: 'Message was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def message_params
    params.require(:message).permit(:content)
  end
end
