# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "json"
require "pg"

get "/top" do
  @memos = Memo.read.array
  erb :top
end

post "/top" do
  title = params["title"]
  body = params["body"].gsub(/[\r]/, "").split("\n")
  memo = Memo.read
  Memo.save(memo.add_memo(memo.array.size, title, body))
  redirect "/top"
end

get "/new" do
  erb :new
end

get "/show/:id" do
  number = params[:id].to_i
  memo = Memo.read
  @title, @body, @number = memo.title(number - 1), memo.body(number - 1), number.to_s
  erb :show
end

get "/edit/:id" do
  number = params[:id].to_i
  memo = Memo.read
  @title, @body, @number = memo.title(number - 1), memo.body(number - 1).gsub(/<br>/, "\n"), number.to_s
  erb :edit
end

delete "/show/:id" do
  number = params[:id].to_i
  memo = Memo.read
  Memo.save(memo.delete_memo(number))
  redirect "/top"
end

patch "/edit/:id" do
  number = params[:id].to_i
  title = params["title"]
  body = params["body"].gsub(/[\r]/, "").split("\n")
  memo = Memo.read
  Memo.save(memo.update_memo(number, title, body))
  redirect "/top"
end

class Memo
  attr_accessor :hash, :array

  def self.save(hash)
    Memo.connect.exec_params("DELETE FROM memo;")
    hash["memos"].each do |memo|
      Memo.connect.exec_params("INSERT INTO memo (id, title, body) VALUES ($1, $2, $3)", [memo["id"], memo["title"], memo["body"]])
    end
  end

  def self.read
    hash = {}
    rows = Memo.connect.exec("SELECT * FROM memo ORDER BY id;")
    hash["memos"] = rows.map { |row| row }
    Memo.new(hash)
  end

  def self.connect
    @connection = PG.connect(host: "localhost", user: "postgres", dbname: "memo_app", port: "5432")
  end

  def initialize(hash)
    @hash = hash
    @array = hash["memos"]
  end

  def id(number)
    @array[number]["id"]
  end

  def title(number)
    @array[number]["title"]
  end

  def body(number)
    @array[number]["body"]
  end

  def add_memo(id, title, body)
    @hash["memos"].append({ "id"=>"#{id + 1}", "title"=>"#{title}", "body"=>"#{body.join("<br>")}" })
    @hash
  end

  def update_memo(id, title, body)
    @hash["memos"][id - 1] = { "id"=>"#{id}", "title"=>"#{title}", "body"=>"#{body.join("<br>")}" }
    @hash
  end

  def delete_memo(id)
    @hash["memos"].delete_at(id - 1)
    @hash["memos"].map.with_index(1) { |hash, index| hash["id"] = index }
    @hash
  end
end
