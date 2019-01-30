<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Categories" Codebehind="Categories.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button id="btnNew" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, NewCategory %>"></asp:Button>
        </div>
        <div class="body">
            <asp:GridView ID="grdCategories" runat="server" Width="100%" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="CategoryEdit.aspx?id=<%#Eval("CategoryId") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoCategories %>" /></EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>
</asp:Content>
