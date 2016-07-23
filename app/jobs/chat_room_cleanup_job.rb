class ChatRoomCleanupJob < ApplicationJob
  queue_as :default

  def perform(*args)
    if args[0].users.count == 0
      args[0].destroy
    end
  end
end
