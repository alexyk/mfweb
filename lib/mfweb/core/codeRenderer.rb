# coding: utf-8
module Mfweb::Core
  class CodeRenderer
    def initialize html, code_fragment, anElement, tr: nil
      @html = html
      @fragment = code_fragment
      @anElement = anElement
      @transformer = tr
    end
    
    def call
      leading = (@anElement['indent'] || (heading ? 2 : 0)).to_i
      body = Indenter.new(@fragment.result.gsub("\t", "  ")).leading(leading)
      @html.p('code-label') {@html.text heading} if heading
      attr = @anElement['cssClass'] ? {class: @anElement['cssClass']} : {}
      @html.element('pre', attr) {emit_code_body body}
      if has_children? 'remark'
        @html.p('code-remark') {@transformer.apply @anElement.css('remark')}
      end
    end

    def emit_code_body body
      if @anElement.kind_of? Nokogiri::XML::Element and has_highlights?
        begin
          @html << highlighted_code(body)
        rescue
          @html.error("problem with code highlighting\n%s\n" % $! )
          @html.cdata(body)
        end
      else
        @html.cdata(body)
      end
    end

    def has_children? css_classes
      return false unless @anElement.kind_of? Nokogiri::XML::Element
      return not(@anElement.css(Array(css_classes).join(",")).empty?)
    end

    def has_highlights?
      has_children? CodeHighlighter.highlighting_elements
    end

    def highlighted_code body
      CodeHighlighter.new(@anElement, body).call
    end

    def call_autoheading_method
      method = 'autoheading_' + @anElement['autoheading']
      if self.respond_to? method
        send method
      else
        fail "no autoheading method for %s at %s" % [@anElement['autoheading'], self]
      end
    end

    def heading
      case
      when @anElement['autoheading']
        call_autoheading_method
      when 'true' == @anElement['useClassName']
        "#{@fragment.class}...\n"
      when @anElement['label']
        "#{@anElement['label']}\n"
      when @anElement['class'] #TODO remove class element from old docs
        "class #{@anElement['class']}...\n"
      else nil
      end
    end
    def autoheading_filename
      "#{@fragment.filename}…\n"
    end

    def autoheading_class
      "#{@fragment.class}...\n"
    end

  end
end
