# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "json"

get "/top" do
  unless File.exist?("memo.json") then Memo.save("memo.json", { "memos": [] }) end
  @memo_array = Memo.read("memo.json").array
  erb :top
end

post "/top" do
  p params
  post_title = params["title"]
  post_body = params["body"].gsub(/[\r]/, "").split("\n")
  memo = Memo.read("memo.json")
  Memo.save("memo.json", memo.add_memo(memo, memo.array.size, post_title, post_body))
  redirect "/top"
end

get "/new" do
  erb :new
end

get "/show/:id" do
  number = params[:id].to_i
  memo = Memo.read("memo.json")
  @url_edit, @url_top_id, @url_top  = "/edit/#{number}", "/show/#{number}", "/top"
  @title, @body = memo.fetch_title(number - 1), memo.fetch_body(number - 1)
  erb :show
end

get "/edit/:id" do
  number = params[:id].to_i
  memo = Memo.read("memo.json")
  @url = "/edit/#{number}"
  @title, @body = memo.fetch_title(number - 1), memo.fetch_body(number - 1).gsub(/<br>/, "\n")
  erb :edit
end

delete "/show/:id" do
  number = params[:id].to_i
  memo = Memo.read("memo.json")
  Memo.save("memo.json", memo.delete_memo(memo, number))
  redirect "/top"
end

patch "/edit/:id" do
  number = params[:id].to_i
  update_title = params["title"]
  update_body = params["body"].gsub(/[\r]/, "").split("\n")
  memo = Memo.read("memo.json")
  Memo.save("memo.json", memo.update_memo(memo, number, update_title, update_body))
  redirect "/top"
end

class Memo
  attr_accessor :hash, :array

  def self.save(file, json_data)
    File.open(file, "w") do |f|
      JSON.dump(json_data, f)
    end
  end

  def self.read(file)
    hash = File.open(file) { |f| JSON.load(f) }
    Memo.new(hash)
  end

  def initialize(hash)
    @hash = hash
    @array = hash["memos"]
  end

  def fetch_id(number)
    @array[number]["id"]
  end

  def fetch_title(number)
    @array[number]["title"]
  end

  def fetch_body(number)
    @array[number]["body"]
  end

  def add_memo(instance, id, title, body)
    memo_hash = instance.hash
    memo_hash["memos"].append({ id: id + 1, title: title, body: body.join("<br>") })
    memo_hash
  end

  def update_memo(instance, id, title, body)
    memo_hash = instance.hash
    memo_hash["memos"][id - 1] = { id: id, title: title, body: body.join("<br>") }
    memo_hash
  end

  def delete_memo(instance, id)
    memo_hash = instance.hash
    memo_hash["memos"].delete_at(id - 1)
    memo_hash["memos"].map.with_index(1) { |hash, index| hash["id"] = index }
    memo_hash
  end
end
