<%@ Page Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ContentLibrary" CodeBehind="ContentLibrary.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script type="text/javascript">
        var previewWin;

        function preview(e, id) {
            var je = $.event.fix(e);

            $('#previewWin').html('<img src="GetImage.ashx?Thumb=1&Guid=' + id + '">');
            $('#previewWin').css({ left: je.pageX, top: je.pageY });
            $('#previewWin').show();
        }

        function previewClose() {
            $('#previewWin').hide();
        }
    </script>

    <div id="contentinner" class="base1">

        <div class="toolbar">
            <asp:Button ID="btnNewFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewFolder %>" />
            <asp:Button ID="btnEditFolder" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, EditFolder %>" />
            <Controls:DeleteButton ID="btnDeleteFolder" runat="server" CssClass="toolbtn" CausesValidation="False"
                Text="<%$Resources:Strings, DeleteFolder %>"></Controls:DeleteButton>
                <span class="tooldiv" id="folderLine" runat="server"></span>

                <asp:Button ID="btnNewContent" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, NewContentItem %>" />
                <Controls:DeleteButton ID="btnDelete" runat="server" CssClass="toolbtn" CausesValidation="False"
                    Text="<%$Resources:Strings, DeleteSelectedContentItems %>"></Controls:DeleteButton>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="searcharea">
                    <table role="presentation">
                        <tr>
                            <td>
                                <asp:Label ID="litContentType" runat="server" Text="<%$Resources:Strings, ContentType %>" AssociatedControlID="lstContentType"></asp:Label>
                            </td>
                            <td>
                                <asp:DropDownList ID="lstContentType" runat="server">
                                </asp:DropDownList>
                                &nbsp;&nbsp;
                            </td>
                            <td>
                                <asp:Label ID="litName" runat="server" Text="<%$Resources:Strings, Name %>" AssociatedControlID="txtName"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtName" runat="server"></asp:TextBox>
                            </td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="ltCategory" runat="server" Text="<%$Resources:Strings, Category %>" AssociatedControlID="lstCategory"></asp:Label>
                            </td>
                            <td>
                                <asp:DropDownList ID="lstCategory" runat="server">
                                </asp:DropDownList>
                            </td>
                            <td>
                                <asp:Label ID="litDescription" runat="server" Text="<%$Resources:Strings, Description %>" AssociatedControlID="txtDescription"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtDescription" runat="server"></asp:TextBox>
                            </td>
                            <td></td>
                        </tr>
                        <tr>
                            <td>
                                <asp:Label ID="ltContaining" runat="server" Text="<%$Resources:Strings, Containing %>" AssociatedControlID="txtFullText"></asp:Label>
                            </td>
                            <td>
                                <asp:TextBox ID="txtFullText" runat="server"></asp:TextBox>
                            </td>
                            <td></td>
                            <td></td>
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
                                <%= Resources.Strings.ContentItem%>
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
                                <Controls:PagedGridView ID="grdContentItems" runat="server" Width="100%" AutoGenerateColumns="False"
                                    EnableViewState="False" ShowHeader="True" AllowPaging="True" DataSourceID="odsContentItems"
                                    PageSize="30" CssClass="grd">
                                    <Columns>
                                        <asp:TemplateField ItemStyle-Width="5">
                                            <ItemTemplate>
                                                <input type="checkbox" style="padding: 0px" name="chkDelete" value="<%#Eval("ContentItemGuid")%>" />
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:TemplateField>
                                            <ItemTemplate>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                        <asp:BoundField DataField="FolderName" ItemStyle-Width="80px" Visible="false" />
                                        <asp:BoundField DataField="ModifiedDateUtc" ItemStyle-Width="160px" />
                                        <asp:TemplateField ItemStyle-Width="80px">
                                            <ItemTemplate>
                                                <%#: Intelledox.Manage.General.DisplayName(Eval("ModifiedByGuid"), Eval("ModifiedBy"))%></a>
                                            </ItemTemplate>
                                        </asp:TemplateField>
                                    </Columns>
                                    <EmptyDataTemplate>
                                        <asp:Literal ID="litNoContent" runat="server" Text="<%$Resources:Strings, NoContentItems %>" /></EmptyDataTemplate>
                                </Controls:PagedGridView>
                            </td>
                        </tr>
                    </table>
                </div>

            </ContentTemplate>
        </asp:UpdatePanel>
        <div id="previewWin" style="display: none; position: absolute;">
        </div>
        <asp:ObjectDataSource ID="odsContentItems" runat="server" SelectMethod="GetContentItems" TypeName="Intelledox.Controller.ContentItemController">
            <SelectParameters>
                <asp:Parameter Name="businessUnitGuid" Type="Object" />
                <asp:Parameter Name="contentTypeId" Type="Int32" />
                <asp:Parameter Name="name" Type="String" ConvertEmptyStringToNull="false" />
                <asp:Parameter Name="description" Type="String" ConvertEmptyStringToNull="false" />
                <asp:Parameter Name="categoryId" Type="Int32" />
                <asp:Parameter Name="fullText" Type="String" ConvertEmptyStringToNull="false" />
                <asp:Parameter Name="approval" Type="Object" />
                <asp:Parameter Name="folderGuid" Type="Object" />
                <asp:Parameter Name="userId" Type="Object" />
                <asp:Parameter Name="noFolder" Type="Object" />
            </SelectParameters>
        </asp:ObjectDataSource>
    </div>
</asp:Content>
