<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.UserEdit" Codebehind="UserEdit.aspx.vb" %>
<%@ Reference Control="~/controls/ctlCustomField.ascx" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Save %>" TabIndex="24" />
            <Controls:DeleteButton ID="btnDelete" runat="server" cssclass="toolbtn" CausesValidation="False" TabIndex="25"></Controls:DeleteButton>
            <span class="tooldiv" id="SecurityDiv" runat="server"></span>
            <asp:Button ID="btnSecurity" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Security %>" CausesValidation="false" TabIndex="26" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" TabIndex="27" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table width="100%" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        *<asp:Label ID="lblAccountUsername" runat="server" Text=""
                            AssociatedControlID="txtAccountUsername"></asp:Label></td>
                    <td colspan="3">
                        <asp:TextBox ID="txtAccountUsername" runat="server" TabIndex="1" MaxLength="256"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valUsername" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtAccountUsername" CssClass="wrn"></asp:RequiredFieldValidator>
                        <asp:Button ID="btnReset" runat="server" Text="<%$Resources:Strings, ResetPassword %>" />
                    </td>
                </tr>
                <tr id="trPassword1" runat="server" visible="false">
                    <td>
                        <asp:Label ID="lblAccountPassword" runat="server" Text="<%$Resources:Strings, Password %>"
                            AssociatedControlID="txtAccountPassword"></asp:Label></td>
                    <td colspan="3">
                        <asp:TextBox ID="txtAccountPassword" runat="server" TabIndex="2" MaxLength="50" TextMode="Password" ClientIDMode="Static"></asp:TextBox>
                    </td>
                </tr>
                <tr id="trPassword2" runat="server" visible="false">
                    <td>
                        <asp:Label ID="lblConfirmPassword" runat="server" Text="<%$Resources:Strings, ConfirmPassword %>"
                            AssociatedControlID="txtConfirmPassword"></asp:Label></td>
                    <td colspan="3">
                        <asp:TextBox ID="txtConfirmPassword" runat="server" TabIndex="3" MaxLength="50" TextMode="Password" ClientIDMode="Static"></asp:TextBox>
                        <asp:CustomValidator ID="valPassword" runat="server" ErrorMessage="<%$Resources:Strings, PasswordNoMatch %>" ClientValidationFunction="ValidatePwd" 
                            Display="Dynamic" Enabled="false" CssClass="wrn"></asp:CustomValidator>
                    </td>
                </tr>
                <tr id="trChangePassword" runat="server">
                    <td>&nbsp;</td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkChangePassword" runat="server" Text="<%$Resources:Strings, ChangePassword %>" />
                    </td>
                </tr>
                <tr>
                    <td>&nbsp;</td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkPasswordNeverExpires" runat="server" Text="<%$Resources:Strings, PasswordNeverExpires %>" />
                    </td>
                </tr>
                <tr>
                    <td>&nbsp;</td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkDisable" runat="server" Text="<%$Resources:Strings, DisableAccount %>" />
                    </td>
                </tr>
                <tr>
                    <td>&nbsp;</td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkLockedOut" runat="server" Text="<%$Resources:Strings, LockedOut %>" />
                    </td>
                </tr>
                <tr id="trTwoFactor" runat="server">
                    <td>&nbsp;</td>
                    <td colspan="3">
                        <asp:CheckBox ID="chkTwoFactor" runat="server" Text="<%$Resources:Strings, TwoFactor %>" />
                    </td>
                </tr>
                <tr>
                    <td colspan="4"><hr /></td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblPrefix" runat="server" Text="<%$Resources:Strings, Prefix %>" AssociatedControlID="txtPrefix"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPrefix" runat="server" TabIndex="4" MaxLength="50"></asp:TextBox>
                    <td>
                        <asp:Label ID="lblJobTitle" runat="server" Text="<%$Resources:Strings, JobTitle %>"
                            AssociatedControlID="txtJobTitle"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtJobTitle" runat="server" TabIndex="8" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblFirstName" runat="server" Text="<%$Resources:Strings, FirstName %>"
                            AssociatedControlID="txtFirstName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtFirstName" runat="server" TabIndex="5" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblOrganisation" runat="server" Text="<%$Resources:Strings, Organisation %>"
                            AssociatedControlID="txtOrganisation"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtOrganisation" runat="server" TabIndex="9" MaxLength="100"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblLastName" runat="server" Text="<%$Resources:Strings, LastName %>"
                            AssociatedControlID="txtLastName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtLastName" runat="server" TabIndex="6" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPhoneNumber" runat="server" Text="<%$Resources:Strings, PhoneNumber %>"
                            AssociatedControlID="txtPhoneNumber"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPhoneNumber" runat="server" TabIndex="10" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblEmail" runat="server" Text="<%$Resources:Strings, Email %>" AssociatedControlID="txtEmail"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtEmail" runat="server" TabIndex="7" MaxLength="256"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblFaxNumber" runat="server" Text="<%$Resources:Strings, FaxNumber %>"
                            AssociatedControlID="txtFaxNumber"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtFaxNumber" runat="server" TabIndex="11" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <th colspan="2">
                        <asp:Literal runat="server" Text="<%$Resources:Strings, StreetAddress %>" /></th>
                    <th colspan="2">
                        <asp:Literal runat="server" Text="<%$Resources:Strings, PostalAddress %>" /></th>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>"
                            AssociatedControlID="txtSAddress1"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSAddress1" runat="server" TabIndex="12" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPAddress1" runat="server" Text="<%$Resources:Strings, AddressLine1 %>"
                            AssociatedControlID="txtPAddress1"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPAddress1" runat="server" TabIndex="18" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>"
                            AssociatedControlID="txtSAddress2"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSAddress2" runat="server" TabIndex="13" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPAddress2" runat="server" Text="<%$Resources:Strings, AddressLine2 %>"
                            AssociatedControlID="txtPAddress2"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPAddress2" runat="server" TabIndex="19" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>"
                            AssociatedControlID="txtSSuburb"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSSuburb" runat="server" TabIndex="14" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPSuburb" runat="server" Text="<%$Resources:Strings, SuburbTownCity %>"
                            AssociatedControlID="txtPSuburb"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPSuburb" runat="server" TabIndex="20" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>"
                            AssociatedControlID="txtSState"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSState" runat="server" TabIndex="15" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPState" runat="server" Text="<%$Resources:Strings, StateProvinceRegion %>"
                            AssociatedControlID="txtPState"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPState" runat="server" TabIndex="21" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>"
                            AssociatedControlID="txtSPostal"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSPostal" runat="server" TabIndex="16" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPPostal" runat="server" Text="<%$Resources:Strings, PostalZipCode %>"
                            AssociatedControlID="txtPPostal"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPPostal" runat="server" TabIndex="22" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblSCountry" runat="server" Text="<%$Resources:Strings, Country %>"
                            AssociatedControlID="txtSCountry"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtSCountry" runat="server" TabIndex="17" MaxLength="50"></asp:TextBox>
                    </td>
                    <td>
                        <asp:Label ID="lblPCountry" runat="server" Text="<%$Resources:Strings, Country %>"
                            AssociatedControlID="txtPCountry"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPCountry" runat="server" TabIndex="23" MaxLength="50"></asp:TextBox>
                    </td>
                </tr>
                <tr>
                    <th colspan="4"><asp:Literal ID="litRegionalOptions" runat="server" Text="<%$Resources:Strings, RegionalOptions %>" /></th>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblCulture" runat="server" Text="<%$Resources:Strings, Culture %>" AssociatedControlID="lstCulture"></asp:Label>
                    </td>
                    <td colspan="3">
                        <asp:DropDownList ID="lstCulture" runat="server" EnableViewState="false">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblLanguage" runat="server" Text="<%$Resources:Strings, Language %>" AssociatedControlID="lstLanguage"></asp:Label>
                    </td>
                    <td colspan="3">
                        <asp:DropDownList ID="lstLanguage" runat="server" EnableViewState="false">
                        </asp:DropDownList>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblTimezome" runat="server" Text="<%$Resources:Strings, Timezone %>" AssociatedControlID="lstTimezone"></asp:Label>
                    </td>
                    <td colspan="3">
                        <asp:DropDownList ID="lstTimezone" runat="server" EnableViewState="false">
                        </asp:DropDownList>
                    </td>                    
                </tr>
                <tr id="trAdditional" runat="server" visible="false">
                    <th colspan="4">
                        <asp:Literal ID="litAdditional" runat="server" Text="<%$Resources:Strings, Additional %>" /></th>
                </tr>
                <asp:PlaceHolder ID="plhCustomFields" runat="server"></asp:PlaceHolder>
            </table>
        </div>
    </div>
    <script type="text/javascript">
        function ValidatePwd(src, args) {
            var txt1 = document.getElementById('txtAccountPassword').value;
            var txt2 = document.getElementById('txtConfirmPassword').value;
            var valid = true;

            if (txt1 != txt2) {
                valid = false;
            }

            args.IsValid = valid;
        }
     </script>
</asp:Content>
