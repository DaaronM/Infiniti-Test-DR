<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Manage.master"
    CodeBehind="ConnectorSettings.aspx.vb" Inherits="Intelledox.Manage.ConnectorSettings" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnSave" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Save %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, Back %>" CausesValidation="false" />
        </div>
        <div class="body">
            <div class="msg" id="msg" runat="server" visible="false">
            </div>
            <table align="center" class="editsection" cellspacing="0" role="presentation">
                <tr>
                    <td>
                        <asp:Label ID="lblConnector" runat="server" Text="<%$ Resources:Strings, Connector %>"
                            AssociatedControlID="lstConnectorSettings" ></asp:Label>
                    </td>
                    <td>
                        <asp:DropDownList ID="lstConnectorSettings" runat="server" AutoPostBack="True">
                        </asp:DropDownList>
                    </td>
                </tr>
            </table>
            &nbsp
            <asp:Repeater ID="rptElements" runat="server">
                <HeaderTemplate>
                    <table border="0" align="center" cellspacing="0" class="editsection" role="presentation">
                </HeaderTemplate>
                <ItemTemplate>
                    <tr>
                        <td>
                            <asp:Label runat="server" ID="lblName" Text='<%# TranslateResourcesTerm(DataBinder.Eval(Container.DataItem, "Description"))%>' AssociatedControlID="txtConnectorSettingsElementTypeVal"></asp:Label>
  
                        </td>
                        <td>
                            <asp:TextBox ID="txtConnectorSettingsElementTypeVal" runat="server"
                                Text='<%# DataBinder.Eval(Container.DataItem, "ElementValue")%>' Width="190px" autocomplete="off"></asp:TextBox>
                        </td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate>
                    </table>
                </FooterTemplate>
            </asp:Repeater>
            <div align="center">
                <asp:Label runat="server" ID='lblNone' Text="<%$Resources:Strings, None %>" Visible="false"></asp:Label>
            </div>
        </div>
    </div>
</asp:Content>
