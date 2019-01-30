<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Security" Codebehind="Security.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button id="btnNew" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewRole %>"></asp:Button>
        </div>
        <div class="body">
            <asp:GridView ID="grdRoles" runat="server" Width="100%" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="SecurityEdit.aspx?id=<%#Eval("RoleGuid") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Description"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoRoles %>" /></EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>
</asp:Content>

