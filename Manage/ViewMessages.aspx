<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ViewMessages" Codebehind="ViewMessages.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>

    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>">
            </asp:Button>
        </div>
        <div class="body">
            <asp:GridView ID="grdMessages" runat="server" DataSourceID="datMessages" AutoGenerateColumns="false" Width="100%" EnableViewState="false" BorderWidth="0" CssClass="grd">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <%#GetDescription(Eval("Description"))%>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <%#GetLevelString(Eval("Level"))%>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
            </asp:GridView>
            <asp:XmlDataSource ID="datMessages" runat="server" XPath="Messages/Message" EnableCaching="false">
            </asp:XmlDataSource>
        </div>
    </div>
</asp:Content>