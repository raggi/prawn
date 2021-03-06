# encoding: utf-8

require File.join(File.expand_path(File.dirname(__FILE__)), "spec_helper")  

class PageCounter
  attr_accessor :pages

  def initialize
    @pages = 0
  end

  # Called when page parsing ends
  def end_page
    @pages += 1
  end
end

module PageCounterHelper
  def count_pages        
    output = @pdf.render
    obs = PageCounter.new
    PDF::Reader.string(output,obs) 
    return obs
  end
end
                         
describe "When creating multi-page documents" do 
  extend PageCounterHelper
  
  before { create_pdf }
  
  it "should initialize with a single page" do 
    page_counter = count_pages
    
    page_counter.pages.should == 1            
    @pdf.page_count.should == 1  
  end
  
  it "should provide an accurate page_count" do
    3.times { @pdf.start_new_page }           
    page_counter = count_pages
    
    page_counter.pages.should == 4
    @pdf.page_count.should == 4
  end
  
end   

describe "When beginning each new page" do

  it "should execute codeblock given to Document#header" do
    call_count = 0    
   
    pdf = Prawn::Document.new      
    pdf.header(pdf.margin_box.top_left) do 
      call_count += 1   
    end
    
    pdf.start_new_page 
    pdf.start_new_page 
    pdf.render
    
    call_count.should == 3
  end

end

describe "When ending each page" do

  it "should execute codeblock given to Document#footer" do
   
    call_count = 0    
   
    pdf = Prawn::Document.new      
    pdf.footer([pdf.margin_box.left, pdf.margin_box.bottom + 50]) do 
      call_count += 1   
    end
    
    pdf.start_new_page 
    pdf.start_new_page 
    pdf.render
    
    call_count.should == 3
  end

  it "should not compress the page content stream if compression is disabled" do

    pdf = Prawn::Document.new(:compress => false)
    content_stub = pdf.ref({})
    content_stub.should.receive(:compress_stream).never.and_return(true)

    pdf.instance_variable_set("@page_content", content_stub)
    pdf.text "Hi There" * 20
    lambda { pdf.render }.should.not.raise
  end

  it "should compress the page content stream if compression is enabled" do

    pdf = Prawn::Document.new(:compress => true)
    content_stub = pdf.ref({})
    content_stub.should.receive(:compress_stream).and_return(true)

    pdf.instance_variable_set("@page_content", content_stub)
    pdf.text "Hi There" * 20
    lambda { pdf.render }.should.not.raise
  end

end                                 

class PageDetails      
  
  def begin_page(params)
    @geometry = params[:MediaBox]
  end                       
  
  def size
    @geometry[-2..-1] 
  end
  
end

def detect_page_details
  output = @pdf.render
  obs = PageDetails.new
  PDF::Reader.string(output,obs) 
  return obs      
end

describe "When setting page size" do
  it "should default to LETTER" do
    @pdf = Prawn::Document.new
    page = detect_page_details
    page.size.should == Prawn::Document::PageGeometry::SIZES["LETTER"]    
  end                                                                  
  
  (Prawn::Document::PageGeometry::SIZES.keys - ["LETTER"]).each do |k|
    it "should provide #{k} geometry" do
      @pdf = Prawn::Document.new(:page_size => k)
      page = detect_page_details
      page.size.should == Prawn::Document::PageGeometry::SIZES[k]
    end
  end
  
  it "should allow custom page size" do 
      @pdf = Prawn::Document.new(:page_size => [1920, 1080] )
      page = detect_page_details
      page.size.should == [1920, 1080]
  end

end       

describe "When setting page layout" do
  it "should reverse coordinates for landscape" do
    @pdf = Prawn::Document.new(:page_size => "A4", :page_layout => :landscape)
    page = detect_page_details
    page.size.should == Prawn::Document::PageGeometry::SIZES["A4"].reverse
  end   
end

describe "The mask() feature" do
  it "should allow transactional restoration of attributes" do
    @pdf = Prawn::Document.new
    y, line_width = @pdf.y, @pdf.line_width
    @pdf.mask(:y, :line_width) do
      @pdf.y = y + 1
      @pdf.line_width = line_width + 1
      @pdf.y.should.not == y
      @pdf.line_width.should.not == line_width
    end
    @pdf.y.should == y
    @pdf.line_width.should == line_width 
  end
end

describe "The render() feature" do
  if "spec".respond_to?(:encode!)
    it "should return a 8 bit encoded string on a m17n aware VM" do
      @pdf = Prawn::Document.new(:page_size => "A4", :page_layout => :landscape)
      @pdf.line [100,100], [200,200]
      str = @pdf.render
      str.encoding.to_s.should == "ASCII-8BIT"
    end
  end
end
