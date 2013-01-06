# -*- encoding: utf-8 -*-
require 'digest/sha1'

module UserAuthenticate
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  def self.included(base)
    base.validates_presence_of     :login, :firstname, :lastname
    base.validates_length_of       :login,    :within => 3..40
    base.validates_uniqueness_of   :login, :case_sensitive => false
    base.before_save :encrypt_password

    base.validates_confirmation_of :password, :if => :password_required?, :message => '確認パスワード入力が一致していません'
    base.validates_length_of :password, { :minimum => 8, :if => :password_required? , :message => 'パスワードは8文字以上にしてください'}
    base.validates_length_of :password, { :maximum => 40, :if => :password_required?, :message => 'パスワードは40文字以下にしてください' }
    base.extend(ClassMethods)
  end

  module ClassMethods
    def hashed(str)
      # check if a salt has been set...
      if SALT == nil
        raise "You must define a :salt value in the configuration for the LoginEngine module."
      end

      return Digest::SHA1.hexdigest("#{SALT}--#{str}--}")[0..39]
    end

    def salted_password(salt, hashed_password)
      hashed(salt + hashed_password)
    end

    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      u = find_by_login(login) # need to get the salt
      u && u.authenticated?(password) ? u : nil
    end

    # Encrypts some data with the salt.
    def encrypt(password, salt)
      salted_password(salt, hashed(password))
    end
  end

  def validate
    if password_required?
      if check_history
        errors.add(:user_error, '設定したパスワードは最近使われています')
        return false
      end
      if (not(password.match(/[0-9]/) and password.match(/[a-zA-Z]/)))
        errors.add(:user_error,"パスワードには少なくとも1文字以上の英文字と数字を混ぜ合わせてください")
        return false
      end
    end
  end

  def check_history
    return if password.blank?
    n = SysConfig.find(:first, :conditions => ["config_section = ? and config_key = ?",'password_config','remember_count']).value1.to_i
    PasswordHistory.find(:all, :conditions => ["login = ?", login], :limit => n, :order => "id desc").each{|x|
      return true if x.crypted_password == self.class.salted_password(x.salt, self.class.hashed(password))
    }
    return false
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = User.hashed("salt-#{Time.now}") if self.salt.blank?
    self.crypted_password = encrypt(password)
    self.password_changed_at = Time.now
  end

  protected
    def password_required?
      crypted_password.blank? || !password.blank?
    end
end
