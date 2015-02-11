# coding: utf-8

require 'bundler'
Bundler.require

require 'logger'
require 'date'

class AutoWebcamTrans
  def initialize(logger = nil)
    #loggerインスタンスが無ければ作る
    @logger = logger || Logger.new(STDERR)

    # .ENVファイルロード
    Dotenv.load

    @fswebcam = ENV["FSWEBCAMPATH"] || '/usr/bin/fswebcam'

    @skipframes = ENV["SKIPFRAMES"] ? ENV["SKIPFRAMES"].to_i : 70

    # 当スクリプトファイルの所在
    @scriptdir = File.expand_path(File.dirname(__FILE__))
  end

  def exec(fileName = nil)
    if fileName == nil then
      imgDir = File.join(@scriptdir, "img/")
      # 現在時刻を元に一時ファイル名を作る
      fileName = DateTime.now.strftime("%Y-%m-%d-%H_%M_%S.jpg")
      fileName = File.join(imgDir, fileName)
    end

    # 撮影
    shoot(fileName)

    # ファイル転送
    scpTransfer(fileName)
  end

  def shoot(filename)
    shootLog = `#{@fswebcam} -S #{@skipframes} #{filename}`

    @logger.info(shootlog)
  end

  def scpTransfer(filename)
    # ファイル存在確認
    unless File.exist? filename then
      @logger.error("File #{filename} not found.")
      return
    end

    hostname = ENV["SCPHOST"]
    username = ENV["SCPUSER"]
    password = ENV["SCPPASS"]
    port = ENV["SCPPORT"]
    remotedir = ENV["SCPREMOTEDIR"]

    remotepath = File.join(remotedir, File.basename(filename))
    Net::SSH.start(hostname, username, :password => password, :port => port) do |ssh|
      ssh.scp.upload! filename, remotepath
    end

    @logger.info("Upload #{filename} success.")
  end
end

# 自身を実行した場合にのみ起動
if __FILE__ == $PROGRAM_NAME then
  logger = Logger.new('log/webcam.log', 0, 5 * 1024 * 1024)
  webcam = AutoWebcamTrans.new(logger)

  webcam.exec
end
