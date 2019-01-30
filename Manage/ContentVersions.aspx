<%@ Page Title="" Language="VB" MasterPageFile="~/Manage.master" AutoEventWireup="false" Inherits="Intelledox.Manage.ContentVersions" CodeBehind="ContentVersions.aspx.vb" %>

<%@ Register TagPrefix="Controls" Namespace="Intelledox.Manage" Assembly="Intelledox.Manage" %>
<asp:Content ID="Content1" ContentPlaceHolderID="Content" runat="Server">
    <asp:ScriptManager ID="ScriptManager1" runat="server">
    </asp:ScriptManager>
    <script src="Scripts/jquery-3.1.1.min.js" type="text/javascript"></script>
    <script type="text/javascript">
        function CheckCompare(checked) {
            var selected = $("input[name='chkVersion']:checked");

            if (selected.length == 2)
                document.getElementById('<%=btnCompare.ClientId %>').disabled = false;
            else
                document.getElementById('<%=btnCompare.ClientId %>').disabled = true;
        }
    </script>
    <div id="contentinner" class="base1">
        <div class="toolbar">
            <asp:Button ID="btnBack" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Back %>"></asp:Button>
            <span class="tooldiv"></span>
            <asp:Button ID="btnCompare" runat="server" CssClass="toolbtn" Text="<%$Resources:Strings, Compare %>" ToolTip="<%$Resources:Strings, CompareTooltip %>" Enabled="false"></asp:Button>
        </div>
        <asp:UpdatePanel ID="up" runat="server">
            <ContentTemplate>
                <div class="body">
                    <div class="msg" id="msg" runat="server" visible="false">
                    </div>
                    <Controls:PagedGridView ID="grdVersions" runat="server" Width="100%" AutoGenerateColumns="False"
                        EnableViewState="False" DataSourceID="odsVersions" PageSize="50" CssClass="grd">
                        <Columns>
                            <asp:TemplateField ItemStyle-Width="1px">
                                <ItemTemplate>
                                    <input type="checkbox" onclick="CheckCompare(this.checked)" name="chkVersion" value="<%# Eval("Version") %>" />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Version %>">
                                <ItemTemplate>
                                    <asp:Label ID="lblContentVersion" runat="server" Text='<%# Eval("Version") %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Modified %>">
                                <ItemTemplate>
                                    <asp:LinkButton ID="lnkExport" runat="server" CommandName="Export"
                                        CommandArgument='<%# Eval("Version") %>'
                                        Text='<% %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, ModifiedBy %>">
                                <ItemTemplate>
                                    <%#: Intelledox.Manage.General.DisplayName(Eval("ModifiedByGuid"), Eval("ModifiedBy"))%></a>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Approved %>">
                                <ItemTemplate>
                                    <asp:Label ID="lblApproved" runat="server" Text='<%# GetApprovedText(Container.DataItem) %>' />
                                    <asp:LinkButton ID="lnkApprove" runat="server" Visible="false"
                                        CommandName="Approve"
                                        CommandArgument='<%# Eval("Version") %>'
                                        Text='<%$Resources:Strings, ApproveNow %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, VersionComment %>">
                                <ItemTemplate>
                                    <asp:Label ID="lblComment" runat="server" Text='<%# GetComment(Eval("VersionComment"), Eval("ImportModifiedDateUtc")) %>' />
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField HeaderText="<%$Resources:Strings, Restore %>">
                                <ItemTemplate>
                                    <asp:LinkButton ID="lnkRestore" runat="server" CommandName="Restore"
                                        CommandArgument='<%# Eval("Version") %>' Text="<%$Resources:Strings, Restore %>" />
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                    </Controls:PagedGridView>
                    <asp:ObjectDataSource ID="odsVersions" runat="server" SelectMethod="GetContentVersions" TypeName="Intelledox.Library.LibraryService">
                        <SelectParameters>
                            <asp:Parameter Name="ProviderName" Type="String" />
                            <asp:Parameter Name="ContentItemGuid" Type="Object" />
                        </SelectParameters>
                    </asp:ObjectDataSource>
                </div>
            </ContentTemplate>
        </asp:UpdatePanel>
    </div>
</asp:Content>
