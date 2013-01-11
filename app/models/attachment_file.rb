# -*- encoding: utf-8 -*-
class AttachmentFile < ActiveRecord::Base
  include AutoTypeName

  belongs_to :parent, :class_name => 'BpMember'


# 拡張子チェックと取得
  def check_and_get_ext(filename)
    ext = File.extname(filename.to_s).downcase
    
    if ext.blank?
      # 取れてない場合はUTF-8コードなのにisoだって言い張ってる困ったチャンだと思われる。
      # UTF-8にしちゃう。
      File.open("ext_test.txt", "wb"){ |f| f.write filename}
      ext = File.extname(NKF.nkf('-w', file_name)).downcase
    end
    
    if !['.txt', '.jpg', '.gif', '.png', '.doc', '.docx', '.xls', '.xlsx', '.pdf'].include?(ext)
#      raise ValidationAbort.new("拡張子がtxt, jpg, gif, png, doc, docx, xls, xlsx, pdfのファイルでなければなりません") 
    end
    
    ext
  end

# 保管
  def store(upfile, store_file_name)
    if upfile.respond_to? 'read'
      store_file(upfile, store_file_name)
    else
      store_str(upfile, store_file_name)
    end
  end

  def store_file(upfile, store_file_name)
    store_internal(upfile, store_file_name){|x| x.read }
  end

  def store_str(upfile, store_file_name)
    store_internal(upfile, store_file_name){|x| x }
  end

# 保管フォルダ指定
  def file_dir
    @file_dir ||= File.join(Rails.root, 'files')
  end


# 経歴書の保存ファイル名生成
  def create_store_parent_table_name
    # 「親テーブル名_親テーブルId_添付ファイルId.拡張子」
    store_file_name = "#{self.parent_table_name}_#{self.parent_id}_#{self.id}#{self.extention}"
  end


  def create_by_import(upfile, parent_id, file_name)
    ActiveRecord::Base::transaction do
      # attachmentFileに項目を入れるメソッド
      # 親テーブル名
      self.parent_table_name = "import_mails"
      # 親テーブルId
      self.parent_id = parent_id
      # 添付ファイル名（オリジナルのファイル名）
      if file_name =~ /"(.*)"/
        file_name = $1
      end
      self.file_name = file_name
      # 拡張子
      ext = self.check_and_get_ext(file_name)
      self.extention = ext
      
      self.created_user = 'import_mail'
      self.updated_user = 'import_mail'
      self.save!
      
      # 保存するファイル名
      store_file_name = self.create_store_parent_table_name
      self.store(upfile, store_file_name)
    end
  end

private
  def store_internal(upfile, store_file_name, &block)
    Dir.mkdir file_dir unless File.exist? file_dir
    File.open(File.join(file_dir, store_file_name), "wb"){ |f| f.write(block.call(upfile)) }
  end

end
