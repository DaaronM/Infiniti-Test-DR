<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ProjectFolders" Codebehind="ProjectFolders.aspx.vb" %>
<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>">
            </asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="body">
                    <Controls:PagedGridView ID="grdFolders" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsFolders" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, FolderName %>">
                                <ItemTemplate>
                                    <a href="PublishProject.aspx?FolderID=<%# Eval("Folder_Guid") %>&ID=<%# Eval("Template_Group_Guid") %>&ProjectID=<%=Microsoft.Security.Application.Encoder.HtmlAttributeEncode(Request.QueryString("id"))%>&Type=<%# Eval("Template_Type_Id") %>&FromProjectFolders=1"><%#Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Folder_Name"))%></a>
                                </ItemTemplate>
                            </asp:TemplateField>                            
                        </Columns>
                        <EmptyDataTemplate><asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoFolders %>" /></EmptyDataTemplate>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsFolders" runat="server" SelectMethod="GetFoldersByProject" TypeName="Intelledox.Controller.ProjectController">
                        <SelectParameters>
                            <asp:Parameter Name="ProjectGuid" Type="Object" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
