<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Projects" CodeBehind="Projects.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnNewFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewFolder %>" />
            <asp:Button ID="btnEditFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, EditFolder %>" />
            <Controls:DeleteButton ID="btnDeleteFolder" runat="server" CssClass="toolbtn" CausesValidation="False"
                Text="<%$Resources:Strings, DeleteFolder %>"></Controls:DeleteButton>
            <span class="tooldiv" id="folderLine" runat="server"></span>
            <asp:Button ID="btnImport" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Import %>" ToolTip="<%$Resources:Strings, ImportHelp %>"></asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <asp:Label ID="litName" runat="server" Text="<%$Resources:Strings, Name %>" AssociatedControlID="txtName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtName" runat="server"></asp:TextBox>
                            </td>
                            <td>
                                <asp:Label ID="litType" runat="server" Text="<%$Resources:Strings, Type %>" AssociatedControlID="lstType"></asp:Label>
                            </td>
                            <td>
                                <asp:DropDownList ID="lstType" runat="server">
                                    <asp:ListItem Value="0" Text="<%$Resources:Strings, All %>"></asp:ListItem>
                                    <asp:ListItem Value="1" Text="<%$Resources:Strings, Form %>"></asp:ListItem>
                                    <asp:ListItem Value="2" Text="<%$Resources:Strings, Layout %>"></asp:ListItem>
                                    <asp:ListItem Value="4" Text="<%$Resources:Strings, FragmentPage %>"></asp:ListItem>
                                    <asp:ListItem Value="5" Text="<%$Resources:Strings, FragmentPortion %>"></asp:ListItem>
                                    <asp:ListItem Value="6" Text="<%$Resources:Strings, Dashboard %>"></asp:ListItem>
                                </asp:DropDownList>
                            </td>
                            <td>
                                <asp:Label ID="ltContaining" runat="server" Text="<%$Resources:Strings, DocumentText %>" AssociatedControlID="txtFullText"></asp:Label></td>
                            <td>
                                <asp:TextBox ID="txtFullText" runat="server"></asp:TextBox></td>
                            <td>
                                <asp:Button ID="btnSearch" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Search %>" />
                            </td>
                        </tr>
                    </table>
                </div>

                <div class="body">
                    <table width="100%" role="presentation" class="layoutgrd">
                        <tr>
                            <th>
                                <%=Resources.Strings.Folders%>
                            </th>
                            <th>
                                <%= Resources.Strings.Projects%>
                            </th>
                        </tr>
                        <tr>
                            <td valign="top" width="230">
                                <div class="TreeViewImageSizer">
                                    <asp:TreeView ID="treeFolders" runat="server" ShowExpandCollapse="false" NodeStyle-CssClass="TreeSelectLink" SelectedNodeStyle-CssClass="TreeSelectLinkSelected" SkipLinkText="">
                                    </asp:TreeView>
                                </div>
                            </td>
                            <td valign="top">
                                <Controls:PagedGridView ID="grdProjects" runat="server" Width="100%" AutoGenerateColumns="false" EnableViewState="false" DataSourceID="odsProjects" PageSize="50" CssClass="grd">
                                    <Columns>
                                        <asp:BoundField DataField="Name" />
                                        <asp:BoundField DataField="ProjectTypeId" />
                                        <asp:BoundField DataField="ModifiedDateUtc" ItemStyle-Width="160px" />
                                        <asp:TemplateField ItemStyle-Width="120px">
                                            <ItemTemplate>
                                                <%#: Intelledox.Manage.General.DisplayName(Eval("ModifiedByGuid"), Eval("ModifiedBy"))%>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <EmptyDataTemplate>
                                        <asp:Literal ID="Literal4" runat="server" Text="<%$Resources:Strings, NoProjects %>" />
                                    </EmptyDataTemplate>
                                </Controls:PagedGridView>
                                <asp:ObjectDataSource ID="odsProjects" runat="server" TypeName="Intelledox.Controller.ProjectController"></asp:ObjectDataSource>
                            </td>
                        </tr>
                    </table>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
