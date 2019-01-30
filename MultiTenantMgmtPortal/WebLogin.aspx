<%@ Page Language="VB" AutoEventWireup="false" Inherits="ManagementPortal.WebLogin" Codebehind="WebLogin.aspx.vb" %>
<!DOCTYPE HTML>
<html dir="<%=IIf(System.Threading.Thread.CurrentThread.CurrentUICulture.TextInfo.IsRightToLeft, "rtl", "ltr") %>" lang="<%=System.Threading.Thread.CurrentThread.CurrentUICulture.TwoLetterISOLanguageName%>">
<head id="Head1" runat="server">
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <title>Multi-Tenant Management Portal</title>
    <link rel="shortcut icon" href="favicon.ico">
    <link type="text/css" href="Base.css?v=10.1.2" rel="stylesheet" />
    <link type="text/css" href="StyleSheet.css?v=9.7.6" rel="stylesheet" />
    <style type="text/css">
        .loginControl 
        {
            position:absolute;
            height: 171px;
            width: 300px;
            top: 200px;
            left: 50%;
            margin-left:-150px;
            padding: 6px;
            background-color:#F0F0F0;
            -moz-border-radius: 6px;
            -o-border-radius: 6px;
            -webkit-border-radius: 6px;
            border-radius: 6px;
        }
        body {
            margin: 0px;
            padding: 0px;
            background-color: #CCCCCC;
        }
        .loginHead {
            text-align:right;
            padding:0px 10px 0px 10px;
            text-transform:uppercase;
            font-family: "Sassoon Sans Std Medium", Calibri, Arial, sans-serif;
            letter-spacing:-1px;
            color:#ffffff;
            margin-bottom:6px;
            font-size:20px;
            background-image:url('images/PanelHeaderGradient.png');
            -moz-border-radius: 6px;
            -o-border-radius: 6px;
            -webkit-border-radius: 6px;
            border-radius: 6px;
            -moz-box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.25);
            -webkit-box-shadow: 0px 1px 1px rgba(0, 0, 0, 0.25);
            box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.25);
            background-color: rgb(237, 64, 55);
        }
        .loginBody 
        {
            padding:10px;
            background-color: #E0E0E0;
            -moz-border-radius: 6px;
            -o-border-radius: 6px;
            -webkit-border-radius: 6px;
            border-radius: 6px;
        }
        .loginLabel {
            font-family: "Segoe UI", Calibri, Arial, Helvetica, sans-serif;
            font-size: 10px;
            font-weight: bold;
            color: #000000;
            text-decoration: none;
            width: 30%;
            padding-right: 10px;
        }
        .loginFields {
            height: 20%;
            text-align: left;
            vertical-align: middle;
        }
        .loginButtonCell {
            font-family: "Segoe UI", Calibri, Arial, Helvetica, sans-serif;
            text-align: center;
        }
        #userName, #passWord  {
            width: 200px;
            font-family: "Segoe UI", Calibri, Arial, Helvetica, sans-serif;
            font-size: 12px;
            color: #000000;
        }
        input.button {
            font-size: 13px;
            margin: 5px;
            background: #CCC url('images/ButtonBG.png') repeat-x top;
            border: solid 1px #999;
            text-transform: uppercase;
            color: #333;
            font-weight: bold;
            padding: 4px 10px;
            -moz-border-radius: 4px;
            -o-border-radius: 4px;
            -webkit-border-radius: 4px;
            border-radius: 4px;
            -moz-box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
            -o-box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
            -webkit-box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
            box-shadow: 0px 1px 4px rgba(0, 0, 0, 0.25);
        }
        input.field
        {
            border: 1px solid #8E8E8E;
            -moz-border-radius: 4px;
            -o-border-radius: 4px;
            -webkit-border-radius: 4px;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <form id="form2" runat="server">
        <div>
            <div id="main">
                <div>
                    <div id="wrapper">
                        <div id="divLoginMessage" runat="server">
                        </div>
                        <div class="loginControl" id="tblLoginAdmin" runat="server">
                            <div class="loginHead">
                                <%=Resources.Strings.Login%>
                            </div>
                            <div class="loginBody">
                                <table role="presentation">
                                    <tr>
                                        <td class="loginLabel">
                                            <asp:Label ID="lblUsername" runat="server" CssClass="normaltext" Text="<%$Resources:Strings, Username%>" AssociatedControlID="txtUsername"></asp:Label></td>
                                        <td class="loginFields">
                                            <asp:TextBox ID="txtUsername" runat="server" CssClass="field" Width="200px" TabIndex="1"></asp:TextBox>
                                            <asp:RequiredFieldValidator
                                                ID="valUsername" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtUsername" CssClass="wrn"></asp:RequiredFieldValidator></td>
                                    </tr>
                                    <tr>
                                        <td class="loginLabel">
                                            <asp:Label ID="lblPassword" runat="server" Text="<%$Resources:Strings, Password%>" AssociatedControlID="txtPassword"></asp:Label></td>
                                        <td class="loginFields">
                                            <asp:TextBox ID="txtPassword" runat="server" CssClass="field" TextMode="Password"
                                                Width="200px" TabIndex="2"></asp:TextBox>
                                    </tr>
                                </table>
                                <hr />
                                <div class="loginButtonCell">
                                    <asp:Button ID="btnSignIn" runat="server" CssClass="button" TabIndex="3" Text="<%$Resources:Strings, Login%>"></asp:Button>
                                </div>
                            </div>
                        </div>
                        <div class="loginControl" id="tblChangePassword" runat="server" visible="false">
                            <div class="loginHead">
                               <%=Resources.Strings.RequiredPasswordChange %>
                            </div>
                            <div class="loginBody">
                                <table role="presentation">
                                    <tr>
                                        <td class="loginLabel">
                                            <asp:Label ID="lblChangePassword1" runat="server" CssClass="normaltext" Text="<%$Resources:Strings, NewPassword%>"></asp:Label></td>
                                        <td class="loginFields">
                                            <asp:TextBox ID="txtChangePassword1" runat="server" CssClass="field" Width="200px" TabIndex="1" textmode="Password" MaxLength="50"></asp:TextBox><br />
                                            <asp:RequiredFieldValidator
                                                ID="valPassword1" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtChangePassword1" CssClass="wrn"></asp:RequiredFieldValidator></td>
                                    </tr>
                                    <tr>
                                        <td class="loginLabel">
                                            <asp:Label ID="lblChangePassword2" runat="server" Text="<%$Resources:Strings, ConfirmNewPassword%>"></asp:Label></td>
                                        <td class="loginFields">
                                            <asp:TextBox ID="txtChangePassword2" runat="server" CssClass="field" TextMode="Password"
                                                Width="200px" TabIndex="2" MaxLength="50"></asp:TextBox><br />
                                            <asp:RequiredFieldValidator ID="valPassword2" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtChangePassword2" CssClass="wrn"></asp:RequiredFieldValidator>
                                            <asp:CompareValidator ID="valCompare" runat="server" ErrorMessage="The passwords you typed do not match" ControlToCompare="txtChangePassword1" ControlToValidate="txtChangePassword2" Display="Dynamic" CssClass="wrn"></asp:CompareValidator>
                                        </td>
                                    </tr>
                                </table>
                                <hr />
                                <div class="loginButtonCell">
                                    <asp:Button ID="btnChange" runat="server" CssClass="button" TabIndex="3" Text="<%$Resources:Strings, Change%>"></asp:Button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </form>
</body>
</html>
