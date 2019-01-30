<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.DataObjectsPage" Codebehind="DataObjects.aspx.vb" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" Runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button id="btnNew" runat="server" cssclass="toolbtn" Text="<%$Resources:Strings, NewDataObject %>"></asp:Button>
            <span class="tooldiv"></span>
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>"
                CausesValidation="false" />
        </div>
        <div class="body">
            <asp:GridView ID="grdDataobjects" runat="server" Width="100%" Height="100%" AutoGenerateColumns="False" EnableViewState="False" CssClass="grd" BorderWidth="0">
                <Columns>

                    <asp:TemplateField>
                        <ItemTemplate>
                            <a href="DataObjectEdit.aspx?datasourceid=<%#Microsoft.Security.Application.Encoder.HtmlAttributeEncode(Request.QueryString("DataSourceID"))%>&id=<%#Eval("DataObjectGuid") %>"><%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("DisplayName"))%></a>
                        </ItemTemplate>
                    </asp:TemplateField>
                    <asp:TemplateField><ItemTemplate>
                        <%#GetObjectType(Eval("ObjectType")) %>
                    </ItemTemplate></asp:TemplateField>
                </Columns>
                <EmptyDataTemplate><asp:Literal ID="Literal1" runat="server" Text="<%$Resources:Strings, NoDataObjects %>" /></EmptyDataTemplate>
            </asp:GridView>
        </div>
    </div>
</asp:Content>

