<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.Folders" Codebehind="Folders.aspx.vb" %>

<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnNewFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewFolder %>" />
            <asp:Button ID="btnEditFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, EditFolder %>" />
            <span class="tooldiv"></span>
            <asp:Button ID="btnPublishProject" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, PublishProject %>"
                ToolTip="<%$Resources:Strings, PublishProjectHelp %>" />
        </div>
        <div class="body">
            <table width="98%" role="presentation" class="layoutgrd">
                <tr>
                    <th>
                        <%=Resources.Strings.Folders%>
                    </th>
                    <th>
                        <%=Resources.Strings.Projects%>
                    </th>
                </tr>
                <tr>
                    <td valign="top" width="230">
                        <asp:Repeater ID="rpFolders" runat="server" EnableViewState="false">
                            <ItemTemplate>
                                <asp:HyperLink runat="server" ID="lnk" CssClass="SelectLink TreeViewImageSizer" NavigateUrl="Folders.aspx?ID=">
                                    <asp:Image runat="server" ID="imgFld" ImageUrl="Images/IX_FolderIcon.svg" AlternateText=" " />
                                    <%# Microsoft.Security.Application.Encoder.HtmlEncode(Eval("Name"))%>
                                </asp:HyperLink>
                            </ItemTemplate>
                        </asp:Repeater>
                        <div class="SelectLink">&nbsp;</div>
                    </td>
                    <td valign="top">
                        <asp:Repeater ID="rpTemplateGroups" runat="server" EnableViewState="false">
                            <ItemTemplate>
                                <div class="TreeViewImageSizer">
                                <img src="Images/IX_ProjectIcon.svg" alt=""/>
                                <a href="PublishProject.aspx?FolderID=<%=Microsoft.Security.Application.Encoder.HtmlAttributeEncode(Request.QueryString("ID"))%>&ID=<%#ContentId(Container.DataItem) %>&Type=<%#GetTypeId(Container.DataItem) %>">
                                    <%#ContentName(Container.DataItem)%>
                                </a>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </td>
                </tr>
            </table>
        </div>
    </div>
</asp:Content>
