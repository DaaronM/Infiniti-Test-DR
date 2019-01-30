<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.SecurityEdit" Codebehind="SecurityEdit.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc" TagName="SecurityPermissions" Src="Controls\SecurityPermissions.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
 <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False" TabIndex="25"></Controls:DeleteButton>
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, RoleName %>"
                            AssociatedControlID="txtName"></asp:Label></td>
                    <td>
                        <asp:TextBox ID="txtName" runat="server" MaxLength="50" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
            </table>
            <table align="center" role="presentation">
                <tr>
                    <td>
                        <br />
                        <table class="subfield" cellspacing="0" width="100%" role="presentation">
                            <tr class="base3 titlerow">
                                <td><%=Resources.Strings.Permissions%></td>
                            </tr>
                            <tr class="inforow">
                                <td><%=Resources.Strings.InfoRolePermissions%></td>
                            </tr>
                            <tr>
                                <td>
                                    <uc:SecurityPermissions id="chkSecurityPermissions" runat="server" />
                                </td>
                            </tr>
                         </table>
                    </td>
                </tr>
            </table>
            <br />

        </div>
    </div>
</asp:Content>

