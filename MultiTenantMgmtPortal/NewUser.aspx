<%@ Page Language="VB" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="NewUser.aspx.vb" Inherits="ManagementPortal.NewUser" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSubmit" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Submit %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table class="editsection" style="width:100%;" role="presentation" border="0">
                <tr>
                    <td style="width:15%;">
                        <asp:Label ID="lblTenantName" runat="server" Text="<%$Resources:Strings, TenantName %>"></asp:Label>
                    </td>
                    <td class="style2" style="width:85%;">
                        <asp:Label ID="lblTenantNameText" runat="server"></asp:Label>
                    </td>
                </tr>
                <tr>
                    <td colspan="2"><hr /></td>
                </tr>
                <tr>
                    <td>
                        *<asp:Label ID="lblUsername" runat="server" Text="<%$Resources:Strings, Username %>"
                            AssociatedControlID="txtUsername"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtUsername" runat="server" MaxLength="50"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvUsername" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtUsername" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        *<asp:Label ID="lblPassword" runat="server" Text="<%$Resources:Strings, Password %>"
                            AssociatedControlID="txtPassword"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtPassword" runat="server" MaxLength="50" TextMode="Password"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvPassword" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtPassword" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        <asp:Label ID="lblConfirmPassword" runat="server" Text="<%$Resources:Strings, ConfirmPassword %>"
                            AssociatedControlID="txtConfirmPassword"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtConfirmPassword" runat="server" MaxLength="50" TextMode="Password"></asp:TextBox>
                        <asp:CompareValidator ID="valConfirmPassword" runat="server" ErrorMessage="" 
                            ControlToValidate="txtPassword" ControlToCompare="txtConfirmPassword" EnableClientScript="false" Display="Dynamic" 
                            CssClass="wrn"></asp:CompareValidator>
                    </td>
                </tr>
                <tr>
                    <td colspan="2"><hr /></td>
                </tr>
                <tr>
                    <td>
                        *<asp:Label ID="lblFirstName" runat="server" Text="<%$Resources:Strings, FirstName %>"
                            AssociatedControlID="txtFirstName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtFirstName" runat="server" MaxLength="50"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvFirstName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtFirstName" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        *<asp:Label ID="lblLastName" runat="server" Text="<%$Resources:Strings, LastName %>"
                            AssociatedControlID="txtLastName"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtLastName" runat="server" MaxLength="50"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvLastName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtLastName" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
                <tr>
                    <td>
                        *<asp:Label ID="lblEmail" runat="server" Text="<%$Resources:Strings, Email %>" AssociatedControlID="txtEmail"></asp:Label>
                    </td>
                    <td>
                        <asp:TextBox ID="txtEmail" runat="server" MaxLength="50"></asp:TextBox>
                        <asp:RequiredFieldValidator ID="rfvEmail" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtEmail" CssClass="wrn"></asp:RequiredFieldValidator>
                    </td>
                </tr>
             </table>
        </div>
    </div>
</asp:Content>

