<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.GroupEdit" Codebehind="GroupEdit.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<%@ Register TagPrefix="uc" TagName="SecurityRoles" Src="Controls\SecurityRoles.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
 <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <Controls:DeleteButton ID="btnDelete" runat="server" cssclass="toolbtn" CausesValidation="False" TabIndex="25"></Controls:DeleteButton>
            <span class="tooldiv" id="divAddress" runat="server"></span>
            <asp:Button ID="btnAddress" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Address %>" CausesValidation="false" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <span class="m">*</span><asp:Label ID="lblName" runat="server" Text="<%$Resources:Strings, GroupName %>"
                            AssociatedControlID="txtName"></asp:Label></td>
                    <td>
                        <asp:TextBox ID="txtName" runat="server" MaxLength="100" CssClass="fld"></asp:TextBox><asp:RequiredFieldValidator
                            ID="valName" runat="server" ErrorMessage="" Display="Dynamic" ControlToValidate="txtName" CssClass="wrn"></asp:RequiredFieldValidator></td>
                </tr>
                <tr id="trExternalGroup" runat="server">
                    <td>
                        <asp:Label ID="lblExternalGroup" runat="server" Text="<%$Resources:Strings, ExternalGroup %>"
                            AssociatedControlID="chkExternalGroup"></asp:Label></td>
                    <td>
                        <asp:CheckBox ID="chkExternalGroup" runat="server" />
                    </td>
                </tr>
            </table>
            <table align="center" role="presentation">
                <tr>
                    <td>
                        <br />
                        <table class="subfield" cellspacing="0" width="80%" align="center" role="presentation">
                            <tr class="base3 titlerow">
                                <td><%=Resources.Strings.Roles%></td>
                            </tr>
                            <tr class="inforow">
                                <td><%=Resources.Strings.InfoGroupRoles%></td>
                            </tr>
                            <tr>
                                <td><uc:SecurityRoles id="chkSecurityRoles" runat="server" /></td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

