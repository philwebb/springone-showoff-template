#!/usr/bin/env ruby
require 'rubygems'
require 'RMagick'
require 'capybara'
require 'capybara/dsl'

# ================================================================
# Collect input args
# ================================================================
begin
  URL = ARGV[0]
  PAGES = ARGV[1].split('~').map(&:to_i)
  DIMENSION = "1260x720".split('x').map(&:to_i)
  OUTPUT = ARGV[2]
rescue
  puts [
    "= USAGE:",
    "",
    "  $ #{$0} url pages output",
    "",
    "= WHERE:",
    "* url        ... url to access the showoff preso (eg. http://0.0.0.0:9090)",
    "* pages      ... range of pages to cover (eg. 1~3)",
    "* output     ... the path for the generated pdf (eg. /tmp/final.pdf)",
    "",
    "= EXAMPLE:",
    "",
    "  $ #{$0} http://localhost:9090 1~3 /tmp/final.pdf",
    "",
  ].join("\n")
  exit
end

# ================================================================
# Screen shooter
# ================================================================
class Shooter < Struct.new(:dimension, :shoot)

  include Magick

  DIR = '/tmp'

  def initialize(dimension, &shoot)
    super(dimension, shoot)
  end

  def take(i)
    pdf = png_path(i) # pdf_path(i)
    (@pdfs ||= []) << pdf
    Image.new(1260, 720).composite(area(i), 0, 0, OverCompositeOp).write(pdf)
  end

  def dump(output)
    ImageList.new(*@pdfs).write(OUTPUT) {
      self.quality = 100
      self.density = '140'
    }
  end

  private

    def pdf_path(i)
      png_path(i).sub(/png$/, 'pdf')
    end

    def png_path(i)
      DIR + '/' + "#{i}".rjust(4,'0') + '.png'
    end

    def area(i)
      png = png_path(i)
      shoot.call(png)
      Image.read(png).first.crop(0, 248, 1260, 720).sharpen()
    end

end

# ================================================================
# Loop through the pages & take screenshots
# ================================================================
Capybara.using_driver(:selenium) do |c|
  include Capybara

  screen = Shooter.new(DIMENSION) do |path|
    page.driver.browser.save_screenshot(path)
  end

  PAGES[0].upto(PAGES[-1]).each do |i|
    visit [URL, "\##{i}"].join('/')
    sleep 0.5
    screen.take(i)
  end

  screen.dump(OUTPUT)
end

# __END__
