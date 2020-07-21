# frozen_string_literal: true

module DownloadHelpers
  TIMEOUT = 5
  PATH = Capybara.save_path

  def self.downloads
    create_directory unless PATH.exist?
    PATH.children
  end

  def self.downloaded_file(file, timeout: TIMEOUT)
    wait_for_download(file, timeout)
    File.read(path_to(file)).tap do |_|
      remove_downloads
    end
  end

  def self.path_to(file)
    PATH.join(file)
  end

  def self.wait_for_download(file, timeout = TIMEOUT)
    Timeout.timeout(timeout) do
      sleep 0.1 until downloaded?(file)
    end
  rescue Timeout::Error
    raise StandardError, "Could not open #{file} after #{timeout} seconds"
  end

  def self.downloaded?(file)
    # Lots of the code in this file seems to be using this source:
    # <https://collectiveidea.com/blog/archives/2012/01/27/testing-file-downloads-with-capybara-and-chromedriver>
    # Comment on November 25, 2013 at 16:26 PM seems to have the same problem that we have on getting an
    # empty file and they seem to solve it by altering the order of this condition. For more info check
    # original source.
    path_to(file).exist? && !downloading?
  end

  def self.downloading?
    # if the folder has a file with a particular extension, we know it is still downloading
    # convert from array of Pathname to array of strings, so can use grep successfully
    downloads_strings = downloads.map(&:to_s)
    downloads_strings.grep(/\.crdownload$/).any?
    # downloads_strings.grep(/\.part$/).any? # uncomment if switch to using Firefox
  end

  def self.remove_downloads
    FileUtils.rm_r(downloads, force: true)
  end

  def self.create_directory
    PATH.parent.mkdir unless PATH.parent.exist?
    PATH.mkdir
  end
end
