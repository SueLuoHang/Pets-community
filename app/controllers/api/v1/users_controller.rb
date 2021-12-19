class Api::V1::UsersController < Api::V1::BaseController

  def login
    user = get_user

    if user.blank?
      render_error(user)
    end
      render json: {
        user: user,
        headers: {
          "X-USER-EMAIL" => user.email,
          "X-USER-TOKEN" => user.authentication_token
        }
      }
  end

  def show
    @user = User.find(params[:id])
  end

  private
  def get_user
    mp_openid = fetch_wx_open_id(params[:code])["openid"]
    # p "================", mp_openid
    user = User.find_by(mp_openid: mp_openid)
    # p "==========", user
    # return nil if user.blank?

    if user.blank?
      user = User.create!(
        mp_openid: mp_openid,
        email: "#{mp_openid.downcase}_#{SecureRandom.hex(3)}@wx.com",
        password: Devise.friendly_token(20)
      )
    end
    return user
  end

  def fetch_wx_open_id(code)
    app_id = Rails.application.credentials.dig(:wx_mp, :app_id)
    app_secret = Rails.application.credentials.dig(:wx_mp, :app_secret)
    url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{app_id}&secret=#{app_secret}&js_code=#{code}&grant_type=authorization_code"

    response = RestClient.get(url)
    result = JSON.parse(response.body)
    result
  end

  def render_error(object)
    render json: { status: 'fail', res: 'fail', errors: object.errors.full_messages },
    status: 422
  end
end
