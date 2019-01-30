<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Datasources" Codebehind="Datasources.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
 <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button id="btnNew" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, NewDataSource %>"></asp:Button>
        </div>
        <div class="body">
            <asp:GridView ID="grdDatasources" runat="server" Width="100%" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="DatasourceEdit.aspx?id=<%#Eval("DataServiceGuid") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:BoundField DataField="ProviderName" />
                </Columns>
                <EmptyDataTemplate><asp:Literal ID="Literal1" runat="server" Text="<%$Resources:Strings, NoDataSources %>" /></EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>
</asp:Content>
