<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.LicenseManager"
    CodeBehind="LicenseManager.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <link href="Content/toastr.css?v=9.7.3" rel="stylesheet" />
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="scripts/toastr.js?v=9.7.3" type="text/javascript"></script>
     <style>
        .fullwidth {
            width: 100%;
        }

        .style2 {
            width: 325px;
        }
    </style>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>"></asp:Button>
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblLicenseHolder" runat="server" Text="<%$Resources:Strings, LicenseHolder %>"
                            AssociatedControlID="txtLicenseHolder"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtLicenseHolder" runat="server" MaxLength="255" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valLicenseHolder" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtLicenseHolder"
                            CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblTenancyKeyText" runat="server" Text="<%$Resources:Strings, TenancyKey %>"
                            AssociatedControlID="lblTenancyKey"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblTenancyKey" runat="server" CssClass="tenant-key"></asp:Label>
                        <div>
                            <asp:Label ID="lblTenancyKeyExpiry" runat="server"> </asp:Label>
                            <button class="clip" type="button" data-clipboard-action="copy" data-clipboard-target="#ctl00_Content_lblTenancyKey"><%=Resources.Strings.CopyToClipboard%></button>
                            <asp:Button ID="btnGenTenancyKey" runat="server" Text="<%$Resources:Strings, GenerateNewKey %>"></asp:Button>                            
                        </div>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblLicenseTypeText" runat="server" Text="<%$Resources:Strings, LicenseType %>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblLicenseType" runat="server"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblUserCountText" runat="server" Text="<%$Resources:Strings, UserLicenses %>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblUserCount" runat="server"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblMobileAppUserCountText" runat="server" Text="<%$Resources:Strings, MobileAppUserLicenses %>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblMobileAppUserCount" runat="server"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblAnonymousProjectCountText" runat="server" Text="<%$Resources:Strings, AnonymousProjectLicenses%>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblAnonymousProjectCount" runat="server"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblInternalProjectCountText" runat="server" Text="<%$Resources:Strings, InternalProjectLicenses%>"></asp:Label>
                    </td>
                    <td>
                        <asp:Label ID="lblInternalProjectCount" runat="server"></asp:Label>
                    </td>
                </tr>
            </table>
            <br />
            <br />
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <th colspan="2">
                        <%=Resources.Strings.Modules%>
                    </th>
                </tr>
                <tr>
                    <td>
                        <asp:ListBox ID="lstUserModuleLicenses" runat="server" CssClass="fld" Width="525px"
                            Rows="10"></asp:ListBox>
                    </td>
                </tr>
            </table>
            <br />
            <br />
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblFile" runat="server" Text="<%$Resources:Strings, UploadNewLicenseFile %>"
                            AssociatedControlID="fileUpload"></asp:Label></td>
                    <td>
                        <asp:FileUpload ID="fileUpload" runat="server" Width="400px" />

                    </td>
                </tr>
            </table>
        </div>
    </div>
     <script src="scripts/clipboard.min.js"></script>
    <script>
        $(document).ready(function () {
            toastr.options =
                {
                    "timeOut":
                    "3000",
                    "extendedTimeOut":
                    "1000"
                };  

            var clipboard = new Clipboard('.clip');
            clipboard.on('success', function (e) {
                toastr.success("<%=Resources.Strings.KeyCopied%>");
             });

             clipboard.on('error', function (e) {
                 console.log(e);
             });
        }
        );
    </script>
</asp:Content>
