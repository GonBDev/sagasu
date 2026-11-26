class MessagesController < ApplicationController
  def create
    chat = Chat.for_user(current_user).find(params[:chat_id])
    message = chat.messages.build(sender: current_user, content: params.require(:message).permit(:content)[:content])

    if message.save
      redirect_to chat_path(chat, anchor: "message-composer"), status: :see_other
    else
      redirect_to chat_path(chat, anchor: "message-composer"),
                  alert: message.errors.full_messages.to_sentence, status: :see_other
    end
  end
end
