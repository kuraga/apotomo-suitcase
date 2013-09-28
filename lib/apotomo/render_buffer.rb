module Apotomo
  class RenderBuffer
    def initialize(w)
      @widget = w
      @buffer = ""
    end

    def <<(str)
      @buffer << str
    end

    def method_missing(method_name, *args)
      @buffer << @widget.send(method_name, *args)
    end

    def to_s
      @buffer
    end
  end
end
