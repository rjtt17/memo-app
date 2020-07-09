# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "json"

get "/top" do
  unless File.exist?("memo.json") then Memo.new.save("memo.json", { "memos": [] }) end
  @memo_array = Memo.new.read("memo.json")["memos"]
  erb :top
end

post "/top" do
  @memo = params["memo"].gsub(/[\r]/, "").split("\n")
  @memo_hash = Memo.new.read("memo.json")
  @new_memo = { id: @memo_hash["memos"].size + 1, title: @memo[0], body: @memo[1..-1].join("<br>") }
  @memo_hash["memos"].append(@new_memo)
  Memo.new.save("memo.json", @memo_hash)
  redirect "/top"
end

get "/new" do
  erb :new
end

get "/show/:id" do
  @memo_array = Memo.new.read("memo.json")["memos"]
  @url_edit, @url_top_id, @url_top  = "/edit/" + params[:id], "/show/" + params[:id], "/top"
  @title = @memo_array[params[:id].to_i - 1]["title"]
  @body = @memo_array[params[:id].to_i - 1]["body"]
  erb :show
end

get "/edit/:id" do
  @memo_array = Memo.new.read("memo.json")["memos"]
  @url = "/edit/" + params[:id]
  @title = @memo_array[params[:id].to_i - 1]["title"]
  @body = @memo_array[params[:id].to_i - 1]["body"].gsub(/<br>/, "\n")
  erb :edit
end

delete "/show/:id" do
  @memo_hash = Memo.new.read("memo.json")
  @memo_hash["memos"].delete_at(params["id"].to_i - 1)
  @memo_hash["memos"].map.with_index(1) { |hash, index| hash["id"] = index }
  Memo.new.save("memo.json", @memo_hash)
  redirect "/top"
end

patch "/edit/:id" do
  @memo = params["memo"].gsub(/[\r]/, "").split("\n")
  @memo_hash = Memo.new.read("memo.json")
  @new_memo = { id: params["id"].to_i, title: @memo[0], body: @memo[1..-1].join("<br>") }
  @memo_hash["memos"][params["id"].to_i - 1] = @new_memo
  Memo.new.save("memo.json", @memo_hash)
  redirect "/top"
end

class Memo
  def save(file, json_data)
    File.open(file, "w") do |f|
      JSON.dump(json_data, f)
    end
  end

  def read(file)
    File.open(file) { |f| JSON.load(f) }
  end
end

helpers do
  def link_to(url, text)
    %(<a href="/show/#{url}">#{text}</a>)
  end
end

helpers do
  def btn_to(url, text)
    %(<a class="btn btn-primary" href="#{url}" role="button">#{text}</a>)
  end
end

helpers do
  def request_form(url)
    %(<form action='#{url}' method='post'>)
  end
end
