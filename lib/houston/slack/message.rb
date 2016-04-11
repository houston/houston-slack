module Houston::Slack
  class Message

    def initialize(data)
      @data = data
      @processed_text = Hash.new do |hash, flags|
        hash[flags] = flags.inject(text) { |text, flag| self.class.apply(flag, text) }.strip
      end
    end


    def channel
      return @channel if defined?(@channel)
      @channel = Houston::Slack::Channel.find(data["channel"])
    end

    def sender
      return @sender if defined?(@sender)
      @sender = Houston::Slack::User.find(data["user"])
    end

    def timestamp
      data["ts"]
    end

    def text
      return @text if defined?(@text)
      @text = self.class.normalize(data["text"])
    end
    alias :to_str :text

    def to_s(flags=[])
      processed_text[flags]
    end

    def inspect
      "#{text}  (from: #{sender}, channel: #{channel})"
    end


    def respond_to_missing?(method, include_all)
      return true if text.respond_to?(method)
      super
    end

    def method_missing(method, *args, &block)
      return text.public_send(method, *args, &block) if text.respond_to?(method)
      super
    end


    def self.normalize(text)
      text
        .gsub(/[“”]/, "\"")
        .gsub(/[‘’]/, "'")
        .strip
    end



    class << self
      def apply(flag, text)
        send :"_apply_#{flag}", text
      end

      def can_apply?(flag)
        respond_to? :"_apply_#{flag}", true
      end

    private

      def _apply_downcase(text)
        text.downcase
      end

      def _apply_no_punctuation(text)
        # Need to leave @ and # in @mentions and #channels
        text.gsub(/[^\w\s@#]/, "")
      end

      def _apply_no_mentions(text)
        text.gsub(/(?:^|\W+)#{Houston::Slack::Connection::ME}\b/, "")
      end

      def _apply_no_emoji(text)
        text.gsub(/(?::[^:]+:)/, "")
      end
    end

  private
    attr_reader :data, :processed_text
  end
end
