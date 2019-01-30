<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.CustomFields" CodeBehind="CustomFields.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script src="Scripts/TabPages.js?v=8.1" type="text/javascript"></script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnNew" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewCustomField %>"></asp:Button>
        </div>
        <div class="body" style="text-align: center;">
            <div class="msg" id="msg" runat="server" visible="false" />
            <asp:HiddenField ID="hidTabPage" runat="server" ClientIDMode="Static" />
            <asp:HiddenField ID="hidTab" runat="server" ClientIDMode="Static" />
            <div id="tabResponseMetadata" class="tabButton tabButtonActive" runat="server" clientidmode="static">
                <a href="#void" onclick="pageChange('tabResponseMetadata', 'pageResponseMetadata');return false;">
                    <%=Resources.Strings.ResponseMetadata%></a>
            </div>
            <div id="tabUser" class="tabButton" runat="server" clientidmode="static">
                <a href="#void" onclick="pageChange('tabUser', 'pageUser');return false;">
                    <%=Resources.Strings.User%></a>
            </div>
            <div id="tabGroup" class="tabButton" runat="server" clientidmode="static">
                <a href="#void" onclick="pageChange('tabGroup', 'pageGroup');return false;">
                    <%=Resources.Strings.Group%></a>
            </div>
            <div id="tabContact" class="tabButton" runat="server" clientidmode="static">
                <a href="#void" onclick="pageChange('tabContact', 'pageContact');return false;">
                    <%=Resources.Strings.Contact%></a>
            </div>
        </div>
        <div id="pageResponseMetadata" class="tabPage" runat="server" clientidmode="static" style="text-align: left;">
            <asp:GridView ID="grdResponseMetadata" runat="server" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" HorizontalAlign="Center" Width="900px" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="CustomFieldEdit.aspx?id=<%#Eval("ResponseMetadataFieldGuid") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoCustomFields %>" />
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
        <div id="pageUser" class="tabPage" runat="server" clientidmode="static" style="text-align: left; display: none;">
            <asp:GridView ID="grdUserCustomFields" runat="server" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" HorizontalAlign="Center" Width="900px" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="CustomFieldEdit.aspx?id=<%#Eval("Id") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Title"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField>
                        <ItemTemplate><%#GetValidationType(Eval("ValidationType")) %></ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoCustomFields %>" />
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
        <div id="pageGroup" class="tabPage" runat="server" clientidmode="static" style="text-align: left; display: none;">
            <asp:GridView ID="grdGroupCustomFields" runat="server" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" HorizontalAlign="Center" Width="900px" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="CustomFieldEdit.aspx?id=<%#Eval("Id") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Title"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField>
                        <ItemTemplate><%#GetValidationType(Eval("ValidationType")) %></ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoCustomFields %>" />
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
        <div id="pageContact" class="tabPage" runat="server" clientidmode="static" style="text-align: left; display: none;">
            <asp:GridView ID="grdContactCustomFields" runat="server" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" HorizontalAlign="Center" Width="900px" BorderWidth="0">
                <Columns>
                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="CustomFieldEdit.aspx?id=<%#Eval("Id") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Title"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField>
                        <ItemTemplate><%#GetValidationType(Eval("ValidationType")) %></ItemTemplate>
                    </asp:TemplateField>
                </Columns>
                <EmptyDataTemplate>
                    <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoCustomFields %>" />
                </EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>
</asp:Content>

