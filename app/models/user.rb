require"validator/email_validator"

class User < ApplicationRecord
  include TokenGenerateService
  before_validation :downcase_email

  #gem bcrypt
  #1. passwordを暗号化する
  #2. password_digest => password
  #3. password_confirmation => パスワードの一致確認
  #4. 一致のバリデーション追加
  #5. authenticate()
  #6. 最大文字数 72文字まで
  #7. User.create() => 入力必須バリデーション, User.update() => ×
  has_secure_password

  #validates
  validates :name, presence: true,
                           length: {
                           maximum: 30,
                           allow_blank: true
                          }

  validates :email, presence: true,
                          email: { allow_blank: true }

  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
  validates :password, presence: true,
                                length: {
                                  minimum: 8,
                                  allow_blank: true
                                },
                                format: {
                                  with: VALID_PASSWORD_REGEX,
                                  message: :invalid_password,
                                  allow_blank: true
                                },
                                allow_nil: true
  validates :activated, inclusion: { in: [ true, false ] }

  ## methods
  # class method  ###########################
  class << self
    # emailからアクティブなユーザーを返す
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end
  # class method end #########################

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    users = User.where.not(id: id)
    users.find_by_activated(email).present?
  end

  # リフレッシュトークンのJWT IDを記憶する
  def remember(jti)
    update!(refresh_jti: jti)
  end

  # リフレッシュトークンのJWT IDを記憶する
  def forget
    update!(refresh_jti: nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
    as_json(only: [:id, :name]).merge(payload).with_indifferent_access
  end
  
  private

    #email小文字化
    def downcase_email
      self.email.downcase! if email
    end
end
