defmodule Interface do
  def withdraw_eth(),
    do:
      Sabv2Contract.withdraw_eth()
      |> Ethers.send(
        signer: Ethers.Signer.Local,
        signer_opts: [private_key: System.get_env("PRIVATE_KEY")],
        value: 0,
        to: System.get_env("CONTRACT_ADDRESS"),
        from: System.get_env("ACCOUNT_NUMBER")
      )
      |> LogWritter.ipt("sx1 withdraw_eth")

  def withdraw_token(token_address),
    do:
      Sabv2Contract.withdraw_token(token_address)
      |> Ethers.send(
        signer: Ethers.Signer.Local,
        signer_opts: [private_key: System.get_env("PRIVATE_KEY")],
        value: 0,
        to: System.get_env("CONTRACT_ADDRESS"),
        from: System.get_env("ACCOUNT_NUMBER")
      )
      |> LogWritter.ipt("sx1 withdraw_token")

  def eth_balance() do
    {:ok, balance} = Ethers.get_balance(System.get_env("CONTRACT_ADDRESS"))

    (balance / 1.0e18)
    |> LogWritter.ipt("sx1 eth_balance")
  end

end
