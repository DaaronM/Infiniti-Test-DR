<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.UserSecurity" CodeBehind="UserSecurity.aspx.vb" %>

<%@ Register TagPrefix="uc" TagName="SecurityRoles" Src="Controls\SecurityRoles.ascx" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" cellpadding="5" width="80%" role="presentation">
                <tr>
                    <td>
                        <table class="subfield" align="center" cellspacing="0" role="presentation">
                            <tr class="base3 titlerow">
                                <td><%=Resources.Strings.Groups%></td>
                            </tr>
                            <tr class="inforow">
                                <td><%=Resources.Strings.InfoUserGroups%></td>
                            </tr>
                            <tr>
                                <td>
                                    <asp:Repeater ID="rpGroups" runat="server">
                                        <HeaderTemplate>
                                            <table cellspacing="0" width="100%" role="presentation">
                                        </HeaderTemplate>
                                        <ItemTemplate>
                                            <tr>
                                                <td>
                                                    <label>
                                                        <asp:CheckBox ID="chkGroup" runat="server" value='<%#Eval("ID")%>' Enabled='<%#Eval("IsNTGroup") = "False"%>' />
                                                        <%#DisplayName(Container.DataItem) %>
                                                    </label>
                                                </td>
                                            </tr>
                                        </ItemTemplate>
                                        <FooterTemplate>
                                            </table>
                                        </FooterTemplate>
                                    </asp:Repeater>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
                <tr>
                    <td>
                        <table class="subfield" align="center" cellspacing="0" role="presentation">
                            <tr class="base3 titlerow">
                                <td><%=Resources.Strings.Roles%></td>
                            </tr>
                            <tr class="inforow">
                                <td><%=Resources.Strings.InfoUserRoles%></td>
                            </tr>
                            <tr>
                                <td>
                                    <uc:SecurityRoles ID="chkSecurityRoles" runat="server" />
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>

