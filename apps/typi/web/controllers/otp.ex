defmodule Typi.OTP do
  def generate_otp() do
    :random.seed(:os.timestamp)
    to_string(round(:random.uniform * 9000) + 1000)
  end
end
