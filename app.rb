require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

set :root, File.dirname(__FILE__)
set :views, Proc.new { File.join(root, 'views') }

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

before %r{/(exam|result)} do
  pass unless request.post?
  @db = SQLite3::Database.new('db/quiz.db', results_as_hash: true)
end

after %r{/(exam|result)} do
  pass unless request.post?
  @db&.close
  @db = nil
end

get '/' do
  @select_quiz_nums = (1..10).to_a
  @default_quiz_num = 5

  erb :index, layout: :layout
end

get '/exam' do
  redirect '/'
end

post '/exam' do
  @quizzes = @db.execute('SELECT * FROM quizzes ORDER BY RANDOM() LIMIT ?', params['quiz_num'].to_i)

  erb :exam, layout: :layout
end

get '/result' do
  redirect '/'
end

post '/result' do
  user_answers = params['answers'] || {}
  @results = []
  @correct_num = 0

  quiz_ids = user_answers.keys.map(&:to_i)
  correct_answers = @db.execute("SELECT id, answer FROM quizzes WHERE id IN (#{quiz_ids.join(',')})").to_h { |row| [row['id'], row['answer']] }

  user_answers.each do |quiz_id, user_answer|
    quiz_id_int = quiz_id.to_i
    question_text = @db.get_first_value('SELECT question FROM quizzes WHERE id = ?', quiz_id_int)
    correct_answer = correct_answers[quiz_id_int]

    is_correct = (correct_answer == user_answer)
    @correct_num += 1 if is_correct

    @results << {
      question: question_text,
      user_answer: user_answer,
      correct_answer: correct_answer,
      is_correct: is_correct
    }
  end

  @total_quiz_num = @results.size

  # X投稿用URL
  share_text = "Regexp? Quizで #{@correct_num} / #{@total_quiz_num} 問正解しました！"
  share_url = request.base_url
  hashtags = 'RegexpQuiz'
  @x_share_url = 'https://twitter.com/intent/tweet?' + URI.encode_www_form(text: share_text, url: share_url, hashtags: hashtags)

  erb :result, layout: :layout
end
