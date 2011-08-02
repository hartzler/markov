require 'rubygems'
require 'engtagger'
tgr = EngTagger.new

#
# {
#   word => {
#     count => c,
#     next => { <recurse> }
#   }
#
mk_chain = {}

def norm(w)
  #w.gsub(/['`",\n:;().?!]/,'').downcase
  w.gsub(/['"`]/,'')
end

def count(h,k)
  h[k]||=0
  h[k]+=1
end

def key(w1,w2)
  "#{w1}:#{w2}"
end

# txt => sentences, sentces => chain

txt = STDIN.read #.gsub(/[\r\n]/,' ')


tgr.get_sentences(txt).each do |s|
#txt.scan(/[A-Z].*?[.?!]/) do |s|
  
#  words = norm(s).split
  words = tgr.get_readable(s).split 

  # start
  if(words.size>1)
    mk_chain[nil]||={}
    count(mk_chain[nil],key(words[0],words[1]))
  end

  # chain
  words.size.times do |i|
    if(i>1)
      mk_chain[key(words[i-2],words[i-1])]||={}
      count(mk_chain[key(words[i-2],words[i-1])],words[i])
    end
    if(i==words.size-1 && words.size>1)
      mk_chain[key(words[i-1],words[i])]||={}
      count(mk_chain[key(words[i-1],words[i])],:end)
    end
  end

end


def make_prob_array(prob_hash)
  total=prob_hash.values.inject(0){|t,v| t+v}.to_f
  prev=0
  prob_hash.map{|k,v| [v/total,k]}.sort{|a,b| a.first<=>b.first}.map do |p|
    p[0]+=prev
    prev=p[0]
    p
  end
end


def rand_word(prob_array)
  if prob_array
    r=rand; prob_array.detect{|s| r<= s.first}.last 
  else
    :end
  end
end

chain = mk_chain.inject({}){|h,v| h[v.first]=make_prob_array(v.last); h}

# generate some sentences
100.times do |i| 
  state = rand_word(chain[nil]).split(":")
  while(state.last!=:end) 
    state << rand_word(chain[key(state[-2],state[-1])])
  end
  puts state.reject{|w| w==:end}.map{|w| w.gsub(/\/.*/,'')}.join(" ")
end
